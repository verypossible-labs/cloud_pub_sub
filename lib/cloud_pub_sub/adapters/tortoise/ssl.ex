defmodule CloudPubSub.Adapters.Tortoise.SSL do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    opts =
      case opts[:cloud_provider] do
        :aws ->
          opts[:device_cert] || raise "AWS IoT requires a :device_cert."
          opts[:device_key] || raise "AWS IoT requires a :device_key."
          opts[:signer_cert] || raise "AWS IoT requires a :signer_cert."
          Keyword.put(opts, :ca_certs, [opts[:signer_cert] | opts[:ca_certs]])

        :gcp ->
          opts[:password] || raise "GCP requires a :password."
          opts
      end

    server_opts = [
      cacerts: opts[:ca_certs],
      host: opts[:host],
      partial_chain: &CloudPubSub.SSL.partial_chain(opts[:cloud_provider], &1),
      port: opts[:port],
      verify: :verify_peer,
      versions: [:"tlsv1.2"],
      cert: opts[:device_cert],
      key: opts[:device_key]
    ]

    server_opts =
      case opts[:cloud_provider] do
        :aws ->
          Keyword.merge(
            [
              server_name_indication: "*.iot.us-east-1.amazonaws.com",
              alpn_advertised_protocols: ["x-amzn-mqtt-ca"]
            ],
            server_opts
          )

        :gcp ->
          Keyword.merge(
            [],
            server_opts
          )
      end

    server = {Tortoise.Transport.SSL, server_opts}

    connection_opts = %{
      cloud_provider: opts[:cloud_provider],
      client_id: opts[:client_id],
      handler: opts[:handler],
      subscriptions: opts[:subscriptions],
      server: server
    }

    connection_opts =
      case opts[:cloud_provider] do
        :aws -> connection_opts
        :gcp -> Map.put(connection_opts, :password, opts[:password])
      end

    CloudPubSub.Adapters.Tortoise.tortoise_connect(connection_opts)
    {:ok, %{client_id: opts[:client_id]}}
  end
end
