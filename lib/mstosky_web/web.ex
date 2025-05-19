defmodule MstoskyWeb.Web do
  @moduledoc """
  The entrypoint for defining your web interface, such as controllers, components, channels, etc.
  This can be used in your application as:
      use MstoskyWeb, :controller
      use MstoskyWeb, :html
  """

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: MstoskyWeb,
        formats: [:html, :json],
        layouts: [html: MstoskyWeb.Layouts]

      @endpoint MstoskyWeb.Endpoint
      @router MstoskyWeb.Router
      import Plug.Conn
      import MstoskyWeb.Gettext
      alias MstoskyWeb.Router.Helpers, as: Routes
      import Phoenix.VerifiedRoutes
    end
  end

  def html do
    quote do
      use Phoenix.Component
      @endpoint MstoskyWeb.Endpoint
      @router MstoskyWeb.Router
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import MstoskyWeb.CoreComponents
      import MstoskyWeb.Gettext
      import Phoenix.Component, only: [embed_templates: 1]
      import Phoenix.VerifiedRoutes
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
