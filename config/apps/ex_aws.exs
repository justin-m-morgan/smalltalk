import Config

config :ex_aws,
  http_client: ExAws.Request.Req,
  region: "us-west-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9090
