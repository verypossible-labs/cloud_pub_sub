defmodule AWSIoT.Adapters.Tortoise.TCP do
  use AWSIoT.Adapters.Tortoise

  def init(opts) do
    server =
      {Tortoise.Transport.Tcp,
       [
         port: Keyword.fetch!(opts, :port),
         host: Keyword.fetch!(opts, :host)
       ]}

    AWSIoT.Adapters.Tortoise.tortoise_connect(opts[:client_id], opts[:subscriptions], server)
    {:ok, %{client_id: opts[:client_id]}}
  end
end
