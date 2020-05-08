import Config

config :aws_iot,
  cert: System.get_env("AWS_IOT_CERT"),
  key: System.get_env("AWS_IOT_KEY"),
  host: System.get_env("AWS_IOT_HOST")

if Mix.env() == :test do
  config :aws_iot,
    adapter: AWSIoTTest.Adapter,
    host: "localhost",
    client_id: "foo"
end
