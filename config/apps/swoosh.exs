import Config

case Mix.env() do
  :dev ->
    # Disable swoosh api client as it is only required for production adapters.
    config :swoosh, :api_client, false

  :prod ->
    # Configures Swoosh API Client
    config :swoosh, api_client: Swoosh.ApiClient.Req

    # Disable Swoosh Local Memory Storage
    config :swoosh, local: false

  :test ->
    # Disable swoosh api client as it is only required for production adapters
    config :swoosh, :api_client, false
end
