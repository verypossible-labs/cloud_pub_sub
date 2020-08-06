defmodule CloudPubSub.Adapters.Tortoise.TCP do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    server =
      {Tortoise.Transport.Tcp,
       [
         port: Keyword.fetch!(opts, :port),
         host: Keyword.fetch!(opts, :host)
       ]}

    CloudPubSub.Adapters.Tortoise.tortoise_connect(opts[:client_id], opts[:subscriptions], server)
    {:ok, %{client_id: opts[:client_id]}}
  end
end
