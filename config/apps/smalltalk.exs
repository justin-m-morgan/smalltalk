import Config

config :smalltalk,
  ecto_repos: [Smalltalk.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :smalltalk, SmalltalkWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SmalltalkWeb.ErrorHTML, json: SmalltalkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Smalltalk.PubSub,
  live_view: [signing_salt: "YPdQOk0I"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :smalltalk, Smalltalk.Mailer, adapter: Swoosh.Adapters.Local

case Mix.env() do
  :dev ->
    # The watchers configuration can be used to run external
    # watchers to your application. For example, we can use it
    # to bundle .js and .css sources.
    config :smalltalk, SmalltalkWeb.Endpoint,
      # Binding to loopback ipv4 address prevents access from other machines.
      # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
      live_reload: [
        web_console_logger: true,
        patterns: [
          ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
          ~r"priv/gettext/.*(po)$",
          ~r"lib/smalltalk_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
        ]
      ],
      code_reloader: true,
      debug_errors: true,
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:smalltalk, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run, [:smalltalk, ~w(--watch)]}
      ]

    # Enable dev routes for dashboard and mailbox
    config :smalltalk, dev_routes: true

  :prod ->
    nil

  :test ->
    # In test we don't send emails
    config :smalltalk, Smalltalk.Mailer, adapter: Swoosh.Adapters.Test
end
