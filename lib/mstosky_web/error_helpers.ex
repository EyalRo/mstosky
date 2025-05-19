defmodule MstoskyWeb.ErrorHelpers do
  use Phoenix.Component

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    assigns = %{errors: Keyword.get_values(form.errors, field)}

    ~H"""
    <%= for error <- @errors do %>
      <span class="text-red-600 text-xs block mt-1">{translate_error(error)}</span>
    <% end %>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # For a full list of supported options, see https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2
    if count = opts[:count] do
      Gettext.dngettext(MstoskyWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MstoskyWeb.Gettext, "errors", msg, opts)
    end
  end
end
