import Config

case Mix.env() do
  :test ->
    config :bcrypt_elixir, log_rounds: 1

  _ ->
    nil
end
