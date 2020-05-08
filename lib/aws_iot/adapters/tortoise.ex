defmodule AWSIoT.Adapters.Tortoise do
  @behaviour AWSIoT.Adapter

  def init(opts) do
    client_id = opts[:client_id]

    Tortoise.Connection.start_link(
      client_id: client_id,
      handler: {AWSIoT.Adapters.Tortoise.Handler, []},
      server: {
        Tortoise.Transport.SSL,
        alpn_advertised_protocols: ["x-amzn-mqtt-ca"],
        cacerts: opts[:cacerts],
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

  def connected?(client_id) do
    case Tortoise.Connection.ping_sync(client_id, 5_000) do
      {:ok, _ref} -> true
      {:error, _error} -> false
    end
  end

  def publish(topic, payload, opts, client_id) do
    opts = if opts == [], do: [qos: 0], else: opts
    Tortoise.publish_sync(client_id, topic, payload, opts)
  end

  def subscribe(topic, opts, client_id) do
    opts = if opts == [], do: [qos: 0], else: opts
    Tortoise.Connection.subscribe(client_id, [topic], opts)
  end

  def unsubscribe(topic, opts, client_id) do
    Tortoise.Connection.unsubscribe(client_id, [topic], opts)
  end
end
