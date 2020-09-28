defmodule CloudPubSub.Adapters.Tortoise.SSL do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    opts
    |> resolve_connection_opts()
    |> CloudPubSub.Adapters.Tortoise.tortoise_connect()

    {:ok, %{client_id: opts[:client_id]}}
  end

  @doc """
  Resolves connection options suitable for `CloudPubSub.Adapters.Tortoise.tortoise_connect/1`.
  """
  def resolve_connection_opts(opts) do
    server = {Tortoise.Transport.SSL, resolve_server_opts(opts)}

    connection_opts = %{
      cloud_provider: opts[:cloud_provider],
      client_id: opts[:client_id],
      handler: opts[:handler],
      subscriptions: opts[:subscriptions],
      server: server
    }

    case opts[:cloud_provider] do
      :aws ->
        connection_opts

      :gcp ->
        opts[:password] || raise "GCP requires a :password."
        Map.merge(connection_opts, %{password: opts[:password]})
    end
  end

  defp resolve_server_opts(raw_opts) do
    opts = default_and_map_and_filter_server_opts(raw_opts)

    case raw_opts[:cloud_provider] do
      :aws ->
        opts[:cert] || raise "AWS IoT requires a :device_cert."
        opts[:key] || raise "AWS IoT requires a :device_key."
        raw_opts[:signer_cert] || raise "AWS IoT requires a :signer_cert."
        Keyword.put(opts, :cacerts, [raw_opts[:signer_cert] | opts[:cacerts]])

      :gcp ->
        opts
    end
  end

  defp default_and_map_and_filter_server_opts(opts) do
    default_opts = %{
      aws: [
        alpn_advertised_protocols: ["x-amzn-mqtt-ca"],
        cacerts: [],
        server_name_indication: "*.iot.us-east-1.amazonaws.com"
      ],
      gcp: [],
      shared: [
        partial_chain: &CloudPubSub.SSL.partial_chain(opts[:cloud_provider], &1),
        verify: :verify_peer,
        versions: [:"tlsv1.2"]
      ]
    }

    opts
    |> Enum.into(default_opts[:shared] ++ default_opts[opts[:cloud_provider]], fn
      {:ca_certs, cacerts} -> {:cacerts, cacerts}
      {:device_cert, cert} -> {:cert, cert}
      {:device_key, key} -> {:key, key}
      kvp -> kvp
    end)
    |> Keyword.take([:cacerts, :host, :partial_chain, :port, :verify, :versions, :cert, :key])
  end
end
