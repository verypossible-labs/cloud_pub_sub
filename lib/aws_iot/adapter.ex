defmodule AWSIoT.Adapter do
  use GenServer

  require Logger

  @default_adapter AWSIoT.Adapters.Tortoise

  @callback init(term) :: {:ok, any} | {:error, any}
  @callback connected?(adapter_state :: any) :: boolean
  @callback publish(
              topic :: String.t(),
              payload :: String.t(),
              opts :: keyword,
              adapter_state :: any
            ) :: {:ok, state :: any} | {{:error, any}, state :: any}
  @callback subscribe(topic :: String.t(), opts :: keyword, adapter_state :: any) ::
              {:ok, state :: any} | {{:error, any}, state :: any}
  @callback unsubscribe(topic :: String.t(), opts :: keyword, adapter_state :: any) ::
              {:ok, state :: any} | {{:error, any}, state :: any}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def connected?() do
    GenServer.call(__MODULE__, :connected?)
  end

  def publish(topic, payload, opts \\ []) do
    GenServer.call(__MODULE__, {:publish, topic, payload, opts})
  end

  def subscribe(topic, opts \\ []) do
    GenServer.call(__MODULE__, {:subscribe, topic, opts})
  end

  def unsubscribe(topic, opts \\ []) do
    GenServer.call(__MODULE__, {:unsubscribe, topic, opts})
  end

  def client_id() do
    GenServer.call(__MODULE__, :client_id)
  end

  def default_subscriptions() do
    GenServer.call(__MODULE__, :default_subs)
  end

  def init(opts) do
    adapter = adapter()
    opts = default_opts(opts)

    case adapter.init(opts) do
      {:ok, adapter_state} ->
        {:ok,
         %{
           adapter: adapter,
           adapter_state: adapter_state,
           client_id: opts[:client_id],
           default_subs: opts[:subscriptions]
         }}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_call(:client_id, _from, s) do
    {:reply, s.client_id, s}
  end

  def handle_call(:default_subs, _from, s) do
    {:reply, s.default_subs, s}
  end

  def handle_call(:connected?, _from, s) do
    {:reply, s.adapter.connected?(s.adapter_state), s}
  end

  def handle_call({:publish, topic, payload, opts}, _from, s) do
    reply = s.adapter.publish(topic, payload, opts, s.adapter_state)
    {:reply, reply, s}
  end

  def handle_call({:subscribe, topic, opts}, _from, s) do
    {reply, adapter_state} = {:ok, s.adapter_state}
    Logger.info("[adapter] :subscribe #{inspect(s.default_subs)} ")

    present =
      Enum.any?(s.default_subs, fn {default_topic, _} ->
        Logger.info(
          "[adapter] :subscribe #{inspect(default_topic)} looking for #{inspect(topic)} "
        )

        case default_topic do
          ^topic ->
            Logger.info("[adapter] :subscribe  #{inspect(topic)} is present")
            true

          _ ->
            false
        end
      end)

    if present == false do
      Logger.info("[adapter] :subscribe #{inspect(topic)} not present")
      {reply, adapter_state} = s.adapter.subscribe(topic, opts, s.adapter_state)
    end

    {:reply, reply, %{s | adapter_state: adapter_state}}
  end

  def handle_call({:unsubscribe, topic, opts}, _from, s) do
    {reply, adapter_state} = s.adapter.unsubscribe(topic, opts, s.adapter_state)
    {:reply, reply, %{s | adapter_state: adapter_state}}
  end

  def handle_info({:connection_status, status}, s) do
    Logger.debug("[AWS] Connection: #{inspect(status)}")
    {:noreply, s}
  end

  def handle_info(result, s) do
    Logger.debug("[adapter] Connection: #{inspect(result)}")
    {:noreply, s}
  end

  def default_opts(opts) do
    opts[:host] ||
      raise """
      AWS IoT requires a :host. You can find this information in the AWS console.
      """

    opts[:client_id] ||
      raise """
      AWS IoT requires a client id to be set to the same value as the serial number.
      """

    signer = Keyword.get(opts, :signer_cert, [])

    opts
    |> Keyword.put_new(:port, 443)
    |> Keyword.put_new(:server_name_indication, '*.iot.us-east-1.amazonaws.com')
    |> Keyword.put_new(:cacerts, [signer | AWSIoT.cacerts()])
    |> Keyword.put_new(:subscriptions, [
      {"$aws/things/U737258/shadow/get/accepted", 1},
      {"$aws/things/U737258/shadow/get/rejected", 1},
      {"$aws/things/U737258/shadow/update", 1},
      {"$aws/things/U737258/shadow/get", 1}
    ])
  end

  defp adapter do
    Application.get_env(:aws_iot, :adapter, @default_adapter)
  end
end
