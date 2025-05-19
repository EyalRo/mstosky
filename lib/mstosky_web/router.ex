defmodule MstoskyWeb.Router do
  use MstoskyWeb, :router

  import MstoskyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MstoskyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MstoskyWeb do
    pipe_through :browser

    post "/session", SessionController, :create
    delete "/session", SessionController, :delete

    post "/users/log_in/session", UserSessionController, :create

    live_session :spa, on_mount: [{MstoskyWeb.UserAuth, :mount_current_user}] do
      live "/", AppLive, :spa
    end

    # Old routes (commented out for SPA migration)
    # live_session :current_user, on_mount: [{MstoskyWeb.UserAuth, :mount_current_user}] do
    #   live "/", PageLive, :home
    #   live "/feed", PageLive, :feed
    #   live "/admin", AdminDashboardLive, :dashboard
    #   live "/admin/dashboard", AdminDashboardLive, :dashboard
    #   live "/admin/users", AdminUsersLive, :index
    #   live "/admin/users/new", AdminUserCreateLive, :new
    #   live "/admin/users/:id/edit", AdminUserEditLive, :edit
    #   live "/admin/posts", AdminPostsLive, :index
    #   live "/users/confirm/:token", UserConfirmationLive, :edit
    #   live "/users/confirm", UserConfirmationInstructionsLive, :new
    # end

    # User settings (authenticated)
    live_session :authenticated, on_mount: [{MstoskyWeb.UserAuth, :ensure_authenticated}] do
      scope "/" do
        pipe_through [:require_authenticated_user]
        live "/settings", UserSettingsLive, :edit
      end
    end

    # User post creation (authenticated)
    scope "/posts" do
      pipe_through [:require_authenticated_user]
      live "/new", PostLive.New, :new
      # post creation is handled by LiveView; remove old post route
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MstoskyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mstosky, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MstoskyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MstoskyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MstoskyWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end
  end

  scope "/", MstoskyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MstoskyWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", MstoskyWeb do
    pipe_through [:browser]
  end
end
