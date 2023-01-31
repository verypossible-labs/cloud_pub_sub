defmodule CloudPubSub.Adapters.Tortoise.TCP do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    server =
      {Tortoise311.Transport.Tcp,
       [
         port: Keyword.fetch!(opts, :port),
         host: Keyword.fetch!(opts, :host)
       ]}

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
