defmodule AWSIoT.Adapter do
  use GenServer

  @default_adapter AWSIoT.Adapters.Tortoise.SSL

  @callback init(term) :: {:ok, any} | {:error, any}
  @callback connected?(adapter_state :: any) :: boolean
  @callback publish(topic :: String.t, payload :: String.t, opts :: keyword, adapter_state :: any) :: :ok | {:error, any}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  def connected?() do
    GenServer.call(__MODULE__, :connected?)
  end

  def publish(topic, payload, opts) do
    GenServer.call(__MODULE__, {:publish, topic, payload, opts})
  end

  def init(opts) do
    adapter = adapter()
    opts = default_opts(opts)

    case adapter.init(opts) do
      {:ok, adapter_state} ->
        {:ok, {adapter, adapter_state}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_call(:connected?, _from, {adapter, adapter_state}) do
    {:reply, adapter.connected?(adapter_state), {adapter, adapter_state}}
  end

  def handle_call({:publish, topic, payload, opts}, _from, {adapter, adapter_state}) do
    {:reply, adapter.publish(topic, payload, opts, adapter_state), {adapter, adapter_state}}
  end

  def default_opts(opts) do
    opts[:host] || raise """
    AWS IoT requires a :host. You can find this information in the AWS console.
    """
    client_id = opts[:client_id] || raise """
    AWS IoT requires a client id to be set to the same value as the serial number.
    """

    signer = Keyword.get(opts, :signer_cert, [])
    opts
    |> Keyword.put_new(:port, 443)
    |> Keyword.put_new(:server_name_indication, '*.iot.us-east-1.amazonaws.com')
    |> Keyword.put_new(:cacerts, [signer | AWSIoT.cacerts()])
    |> Keyword.put_new(:subscriptions, [
      {AWSIoT.topic(:shadow_get_accepted, client_id), 1},
      {AWSIoT.topic(:shadow_get_rejected, client_id), 1}
    ])
  end

  defp adapter do
    Application.get_env(:aws_iot, :adapter, @default_adapter)
  end
end
