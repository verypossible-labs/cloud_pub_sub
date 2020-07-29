defmodule AWSIoT.Adapters.Tortoise do
  defmacro __using__(_opts) do
    quote do
      @behaviour AWSIoT.Adapter

      @impl AWSIoT.Adapter
      def connected?(adapter_state) do
        case Tortoise.Connection.ping_sync(adapter_state.client_id, 5_000) do
          {:ok, _ref} -> {true, adapter_state}
          {:error, _error} -> {false, adapter_state}
        end
      end

      @impl AWSIoT.Adapter
      def publish(topic, payload, opts, adapter_state) do
        opts = if opts == [], do: [qos: 0], else: opts
        {Tortoise.publish_sync(adapter_state.client_id, topic, payload, opts), adapter_state}
      end

      @impl AWSIoT.Adapter
      def subscribe(topic, opts, adapter_state) do
        opts = if opts == [], do: [qos: 0], else: opts
        {Tortoise.Connection.subscribe_sync(adapter_state.client_id, topic, opts), adapter_state}
      end
    end
  end

  def tortoise_connect(client_id, subscriptions, {server_module, server_opts}) do
    server =
      {server_module,
       Keyword.update!(server_opts, :server_name_indication, &String.to_charlist/1)}

    IO.inspect(client_id)
    IO.inspect(server)
    IO.inspect(subscriptions)

    Tortoise.Connection.start_link(
      client_id: client_id,
      handler: {AWSIoT.Adapters.Tortoise.Handler, []},
      server: server,
      subscriptions: subscriptions
    )
  end
end
