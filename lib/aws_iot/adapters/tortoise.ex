defmodule AWSIoT.Adapters.Tortoise do
  defmacro __using__(_opts) do
    quote do
      @behaviour AWSIoT.Adapter

      def connected?(client_id) do
        case Tortoise.Connection.ping_sync(client_id, 5_000) do
          {:ok, _ref} -> true
          {:error, _error} -> false
        end
      end

      def publish(topic, payload, opts, client_id) do
        opts = if opts == [], do: [qos: 0], else: opts
        Tortoise.publish_sync(client_id,  topic,  payload, opts)
      end
    end
  end
end
