import Config

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

case Mix.env() do
  :dev ->
    # Set a higher stacktrace during development. Avoid configuring such
    # in production as building large stacktraces may be expensive.
    config :phoenix, :stacktrace_depth, 20

    # Initialize plugs at runtime for faster development compilation
    config :phoenix, :plug_init_mode, :runtime

  :test ->
    # Initialize plugs at runtime for faster test compilation
    config :phoenix, :plug_init_mode, :runtime
end
