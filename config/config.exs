# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

require Logger

File.ls!("config/apps")
|> Enum.each(fn app ->
  Logger.debug("Loading config from apps/#{app}")
  import_config "apps/#{app}"
end)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
