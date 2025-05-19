defmodule Mstosky.Ops do
  @moduledoc """
  System/ops context for uptime, debug info, and background job status.
  Move all system-level, metrics, and operational helpers here.
  """

  @boot_time_key :mstosky_boot_time

  def boot_time do
    Application.get_env(:mstosky, @boot_time_key) || store_boot_time()
  end

  defp store_boot_time do
    now = System.system_time(:second)
    Application.put_env(:mstosky, @boot_time_key, now)
    now
  end

  def uptime do
    boot = boot_time()
    now = System.system_time(:second)
    diff = max(now - boot, 0)
    hours = div(diff, 3600)
    mins = rem(div(diff, 60), 60)
    secs = rem(diff, 60)
    "#{hours}h #{mins}m #{secs}s"
  end

  # Example stub for background job status
  def job_status do
    # TODO: Replace with real job queue/Oban status
    %{jobs_processing: 0, jobs_failed: 0}
  end

  # Example stub for debug info
  def debug_info do
    %{
      ip_address: "127.0.0.1",
      uptime: uptime(),
      errors: 0,
      warnings: 0
    }
  end
end
