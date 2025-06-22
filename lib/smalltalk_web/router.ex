defmodule SmalltalkWeb.Router do
  use SmalltalkWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SmalltalkLayouts.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug Corsica, origins: "*"
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", SmalltalkWeb do
    pipe_through :browser

    # in each liveview, add one of the following at the top of the module:
    #
    # If an authenticated user must be present:
    # on_mount {SmalltalkWeb.LiveUserAuth, :live_user_required}
    #
    # If an authenticated user *may* be present:
    # on_mount {SmalltalkWeb.LiveUserAuth, :live_user_optional}
    #
    # If an authenticated user must *not* be present:
    # on_mount {SmalltalkWeb.LiveUserAuth, :live_no_user}

    ash_authentication_live_session :authenticated_routes,
      on_mount: [
        {SmalltalkWeb.LiveUserAuth, :live_user_required},
        SmalltalkWeb.Hooks.AssignTalker,
        SmalltalkWeb.Hooks.ForceProfileCreate
      ] do
      live "/", HomeLive, :home

      # live "/account", AccountLive
      # live "/account/contact", AccountLive, :contact
      # live "/account/subscription", AccountLive, :subscription

      live "/profile/show", ProfileLive.Show
      live "/profile/edit", ProfileLive.Edit
      live "/profile/upload_img", ProfileLive.UploadImg
      live "/profile/previous_uploads", ProfileLive.PreviousUploads

      live "/friends", FriendsLive.Index
      live "/friends/search", FriendsLive.Search
      live "/friends/requests", FriendsLive.Requests

      live "/conversations", ConversationsLive.Index, :mine
      live "/conversations/mine", ConversationsLive.Index, :mine

      live "/conversations/awaiting_approval", ConversationsLive.Index, :awaiting_approval
      live "/conversations/is_admin", ConversationsLive.Index, :is_admin
      live "/conversations/search", ConversationsLive.Index, :search

      live "/conversations/lobby", ConversationsLive.Lobby

      live "/conversations/:conversation_id", ConversationsLive.Chat
      live "/conversations/:conversation_id/admin", ConversationsLive.Chat.Admin
    end
  end

  scope "/", SmalltalkWeb do
    pipe_through :browser

    # get "/", PageController, :home

    auth_routes AuthController, Smalltalk.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [
                    {SmalltalkWeb.LiveUserAuth, :live_no_user},
                    SmalltalkWeb.Hooks.AddLogoHook
                  ],
                  overrides: [
                    SmalltalkWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                on_mount: [SmalltalkWeb.Hooks.AddLogoHook],
                overrides: [
                  SmalltalkWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Smalltalk.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [SmalltalkWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Smalltalk.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [SmalltalkWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", SmalltalkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:smalltalk, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SmalltalkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
