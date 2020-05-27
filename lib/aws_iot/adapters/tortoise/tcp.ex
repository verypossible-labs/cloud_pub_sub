defmodule AWSIoT.Adapters.Tortoise.TCP do
  use AWSIoT.Adapters.Tortoise

  def init(opts) do
    client_id = opts[:client_id]
    host = opts[:host] || "localhost"
    port = opts[:port] || 1883

    Tortoise.Connection.start_link(
      client_id: client_id,
      handler: {AWSIoT.Adapters.Tortoise.Handler, []},
      server: {
        Tortoise.Transport.Tcp,
        port: port,
        host: host
      },
      subscriptions: opts[:subscriptions]
    )
    {:ok, client_id}
  end
end
