defmodule AWSIoT.Adapters.Tortoise.SSL do
  use AWSIoT.Adapters.Tortoise

  def init(opts) do
    client_id = opts[:client_id]

    Tortoise.Connection.start_link(
      client_id: client_id,
      handler: {AWSIoT.Adapters.Tortoise.Handler, []},
      server: {
        Tortoise.Transport.SSL,
        alpn_advertised_protocols: ["x-amzn-mqtt-ca"],
        cacerts: (opts[:cacerts]),
        cert: opts[:cert],
        host: opts[:host],
        key: opts[:key],
        partial_chain: &AWSIoT.SSL.partial_chain/1,
        port: opts[:port],
        server_name_indication: opts[:server_name_indication],
        verify: :verify_peer,
        versions: [:"tlsv1.2"]
      },
      subscriptions: opts[:subscriptions]
    )
    {:ok, client_id}
  end
end
