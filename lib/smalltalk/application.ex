defmodule Smalltalk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SmalltalkWeb.Telemetry,
      Smalltalk.Repo,
      {DNSCluster, query: Application.get_env(:smalltalk, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Smalltalk.PubSub},
      # Start a worker by calling: Smalltalk.Worker.start_link(arg)
      # {Smalltalk.Worker, arg},
      # Start to serve requests, typically the last entry
      SmalltalkWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :smalltalk]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Smalltalk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SmalltalkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
