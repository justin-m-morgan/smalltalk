import Config

case Mix.env() do
  :dev ->
    config :phoenix_live_view,
      # Include HEEx debug annotations as HTML comments in rendered markup.
      # Changing this configuration will require mix clean and a full recompile.
      debug_heex_annotations: true,
      # Enable helpful, but potentially expensive runtime checks
      enable_expensive_runtime_checks: true

  :test ->
    # Enable helpful, but potentially expensive runtime checks
    config :phoenix_live_view,
      enable_expensive_runtime_checks: true
end
