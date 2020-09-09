defmodule CloudPubSub.Adapters.Tortoise do
  defmacro __using__(_opts) do
    quote do
      @behaviour CloudPubSub.Adapter

      @impl CloudPubSub.Adapter
      def connected?(adapter_state) do
        case Tortoise.Connection.ping_sync(adapter_state.client_id, 5_000) do
          {:ok, _ref} -> {true, adapter_state}
          {:error, _error} -> {false, adapter_state}
        end
      end

      @impl CloudPubSub.Adapter
      def publish(topic, payload, opts, adapter_state) do
        opts = if opts == [], do: [qos: 0], else: opts
        {Tortoise.publish_sync(adapter_state.client_id, topic, payload, opts), adapter_state}
      end

      @impl CloudPubSub.Adapter
      def subscribe(topic, opts, adapter_state) do
        opts = if opts == [], do: [qos: 0], else: opts
        {Tortoise.Connection.subscribe_sync(adapter_state.client_id, topic, opts), adapter_state}
      end
    end
  end

  def tortoise_connect(opts) do
    {server_module, server_opts} = opts.server

    server_opts =
      case Keyword.fetch(server_opts, :server_name_indication) do
        {:ok, sni} when is_binary(sni) ->
          Keyword.update!(server_opts, :server_name_indication, &String.to_charlist/1)

        :error ->
          server_opts
      end

    server = {server_module, server_opts}
    handler = opts[:handler] || CloudPubSub.Adapters.Tortoise.Handler

    connection_opts = [
      client_id: opts.client_id,
      handler: {handler, []},
      server: server,
      subscriptions: opts.subscriptions
    ]

    connection_opts =
      case opts[:cloud_provider] do
        :aws ->
          connection_opts

        :gcp ->
          Keyword.merge(
            [password: opts.password],
            connection_opts
          )
      end

    Tortoise.Connection.start_link(connection_opts)
  end
end
