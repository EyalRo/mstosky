defmodule Mstosky.FakePostQueue do
  @moduledoc """
  Simple GenServer-based queue for generating fake posts in the background.
  Notifies LiveView subscribers of state changes via Phoenix.PubSub.
  """
  use GenServer

  @pubsub_topic "fake_post_queue"

  # API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Enqueue N fake post generation jobs.
  """
  def enqueue(count) when is_integer(count) and count > 0 do
    GenServer.cast(__MODULE__, {:enqueue, count})
  end

  @doc """
  Enqueue a fake debug job (for UI testing).
  """
  def enqueue_fake_debug_job do
    GenServer.cast(__MODULE__, :enqueue_fake_debug_job)
  end

  @doc """
  Get current queue state, including list of jobs with timestamps.
  """
  def state do
    GenServer.call(__MODULE__, :state)
  end

  # GenServer callbacks
  def init(_) do
    {:ok, %{queue: :queue.new(), processing: false, jobs: []}}
  end

  def handle_call(:state, _from, state) do
    now = System.system_time(:second)

    jobs =
      state.jobs
      |> Enum.map(fn job ->
        duration =
          cond do
            job.status == :processing -> now - (job.started_at || job.enqueued_at)
            true -> now - job.enqueued_at
          end

        Map.put(job, :duration, duration)
      end)

    {:reply,
     %{
       processing: state.processing,
       pending: Enum.count(Enum.filter(jobs, &(&1.status == :queued))),
       jobs: jobs
     }, state}
  end

  def handle_cast({:enqueue, count}, state) do
    now = System.system_time(:second)

    new_jobs =
      Enum.map(1..count, fn _ ->
        %{
          type: :generate_post,
          enqueued_at: now,
          started_at: nil,
          status: :queued,
          duration: 0,
          completed_at: nil,
          processing_duration: 0
        }
      end)

    jobs = state.jobs ++ new_jobs
    new_queue = Enum.reduce(new_jobs, state.queue, fn job, q -> :queue.in(job, q) end)
    state = %{state | queue: new_queue, jobs: jobs}
    maybe_process(state)
  end

  def handle_cast(:enqueue_fake_debug_job, state) do
    now = System.system_time(:second)

    job = %{
      type: :fake,
      enqueued_at: now,
      started_at: nil,
      status: :queued,
      duration: 0,
      completed_at: nil,
      processing_duration: 0
    }

    jobs = state.jobs ++ [job]
    queue = :queue.in(job, state.queue)
    new_state = %{state | jobs: jobs, queue: queue}
    maybe_process(new_state)
  end

  def handle_cast({:complete_fake_debug_job, enqueued_at}, state) do
    now = System.system_time(:second)

    jobs =
      Enum.map(state.jobs, fn job ->
        if job.type == :fake and job.enqueued_at == enqueued_at and job.status == :processing do
          %{
            job
            | status: :done,
              completed_at: now,
              processing_duration: now - (job.started_at || job.enqueued_at)
          }
        else
          job
        end
      end)

    jobs_with_fields =
      Enum.map(jobs, fn j ->
        processing_duration =
          cond do
            (j[:status] == :done and j[:started_at]) && j[:completed_at] ->
              j[:completed_at] - j[:started_at]

            j[:status] == :processing and j[:started_at] ->
              now - j[:started_at]

            true ->
              0
          end

        duration =
          cond do
            (j[:status] == :done and j[:started_at]) && j[:completed_at] ->
              j[:completed_at] - j[:started_at]

            j[:started_at] && j[:status] == :processing ->
              now - j[:started_at]

            j[:enqueued_at] ->
              now - j[:enqueued_at]

            true ->
              0
          end

        Map.merge(j, %{
          duration: duration,
          completed_at: Map.get(j, :completed_at, nil),
          processing_duration: processing_duration
        })
      end)

    notify(%{
      processing: false,
      pending: Enum.count(Enum.filter(jobs_with_fields, &(&1.status == :queued))),
      jobs: jobs_with_fields
    })

    {:noreply, %{state | processing: false, jobs: jobs}}
  end

  def handle_cast({:job_done, result, _job}, state) do
    now = System.system_time(:second)

    jobs =
      case Enum.split_with(state.jobs, &(&1.status != :processing)) do
        {before, [processing_job | rest]} ->
          duration = now - (processing_job.started_at || processing_job.enqueued_at)
          # Ensure all required keys are present in the job
          updated_job =
            Map.merge(processing_job, %{
              status: :done,
              completed_at: now,
              processing_duration: duration,
              result: result || nil
            })

          before ++ [updated_job] ++ rest

        _ ->
          state.jobs
      end

    maybe_process(%{state | processing: false, jobs: jobs})
  end

  def handle_cast(:job_done, state) do
    now = System.system_time(:second)

    jobs =
      case Enum.split_with(state.jobs, &(&1.status != :processing)) do
        {before, [processing_job | rest]} ->
          duration = now - (processing_job.started_at || processing_job.enqueued_at)

          before ++
            [%{processing_job | status: :done, completed_at: now, processing_duration: duration}] ++
            rest

        _ ->
          state.jobs
      end

    maybe_process(%{state | processing: false, jobs: jobs})
  end

  def handle_cast(:clear_done_jobs, state) do
    jobs = Enum.reject(state.jobs, fn job -> job.status == :done end)

    notify(%{
      processing: state.processing,
      pending: Enum.count(Enum.filter(jobs, &(&1.status == :queued))),
      jobs: jobs
    })

    {:noreply, %{state | jobs: jobs}}
  end

  defp maybe_process(%{processing: false, queue: queue, jobs: jobs} = state) do
    case :queue.out(queue) do
      {{:value, job}, rest} ->
        # Mark as processing, update job status and started_at
        now = System.system_time(:second)
        index = Enum.find_index(jobs, &(&1 == job))

        {processing_job, updated_jobs} =
          if index do
            {Enum.at(jobs, index),
             List.update_at(jobs, index, fn j ->
               Map.put(
                 %{j | status: :processing, started_at: now},
                 :result,
                 Map.get(j, :result, nil)
               )
             end)}
          else
            # fallback: find first queued job
            case Enum.split_with(jobs, &(&1.status != :queued)) do
              {done, [first | rest]} ->
                {first,
                 done ++
                   [
                     Map.put(
                       %{first | status: :processing, started_at: now},
                       :result,
                       Map.get(first, :result, nil)
                     )
                   ] ++ rest}

              _ ->
                {nil, jobs}
            end
          end

        jobs = updated_jobs
        notify(%{processing: true, pending: :queue.len(rest), jobs: jobs})

        Task.start(fn ->
          # Simulate a job duration of up to 10 seconds
          Process.sleep(:rand.uniform(10_000))

          result =
            case job.type do
              :generate_post -> Mstosky.Social.generate_fake_posts(1)
              :fake -> :ok
            end

          # Always send the most up-to-date job struct (with status: :processing, started_at: now)
          GenServer.cast(
            __MODULE__,
            {:job_done, result, %{processing_job | status: :processing, started_at: now}}
          )
        end)

        {:noreply, %{state | queue: rest, processing: true, jobs: jobs}}

      _ ->
        notify(%{processing: false, pending: :queue.len(queue), jobs: jobs})
        {:noreply, %{state | processing: false}}
    end
  end

  defp maybe_process(%{processing: true, jobs: _jobs} = state), do: {:noreply, state}

  defp notify(state) do
    Phoenix.PubSub.broadcast(Mstosky.PubSub, @pubsub_topic, {:fake_post_queue, state})
  end

  @doc """
  Subscribe to queue state changes.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Mstosky.PubSub, @pubsub_topic)
  end

  @doc """
  Clear all jobs with status :done from the queue and broadcast the new state.
  """
  def clear_done_jobs do
    GenServer.cast(__MODULE__, :clear_done_jobs)
  end
end
