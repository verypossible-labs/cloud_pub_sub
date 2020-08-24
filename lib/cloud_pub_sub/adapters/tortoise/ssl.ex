defmodule CloudPubSub.Adapters.Tortoise.SSL do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    case opts[:cloud_provider] do
      :aws ->
        opts[:device_cert] || raise "AWS IoT requires a :device_cert."
        opts[:device_key] || raise "AWS IoT requires a :device_key."
        opts[:signer_cert] || raise "AWS IoT requires a :signer_cert."

      :gcp ->
        opts[:password] || raise "GCP requires a :password."
    end

    server_opts = [
      cacerts: opts[:ca_certs],
      # cert: opts[:device_cert],
      host: opts[:host],
      # key: opts[:device_key],
      partial_chain: &CloudPubSub.SSL.partial_chain(opts[:cloud_provider], &1),
      port: opts[:port],
      verify: :verify_none,
      # verify: :verify_peer,
      versions: [:"tlsv1.2"]
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
