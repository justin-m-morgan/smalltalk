import Config

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, level: :error

case Mix.env() do
  :dev ->
    # Do not include metadata nor timestamps in development logs
    config :logger, :default_formatter, format: "[$level] $message\n"

  :prod ->
    # Do not print debug messages in production
    config :logger, level: :info

  :test ->
    # Print only warnings and errors during test
    config :logger, level: :warning
end
