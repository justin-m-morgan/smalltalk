import Config

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  smalltalk: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../..", __DIR__)
  ]
