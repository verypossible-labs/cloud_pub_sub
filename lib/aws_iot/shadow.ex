defmodule AWSIoT.Shadow do
  use GenServer

  alias AWSIoT.{Adapter, Router}
  require Logger
  @filename "aws_iot_shadow.json"


  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, genserver_opts(opts))
  end

  def get_shadow(pid \\ __MODULE__) do
    GenServer.call(pid, :get_shadow)
  end

  def update_shadow(pid \\ __MODULE__, fun) do
    GenServer.call(pid, {:update_shadow, fun})
  end

  def update_shadow_reported(pid \\ __MODULE__,  fun) do
    GenServer.call(pid, {:update_shadow, :reported, fun})
  end


  def get_remote_shadow(pid \\ __MODULE__) do
    GenServer.call(pid, :request_upstream)
  end

  def genserver_opts(opts) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} -> [name: name]
      _ -> []
    end
  end

  def init(opts) do
    filename = opts[:filename] || @filename
    file = Path.join(path(opts[:path]), filename)
    Logger.debug("#{inspect(__MODULE__)} file:#{inspect(file)} opts:#{inspect(opts)}")
    {:ok, timer_ref} = :timer.send_after(30_000, self(), :request_upstream)

    {:ok,
     %{
       file: file,
       shadow: nil,
       upstream_requested?: false
     }, {:continue, File.exists?(file)}}
  end

  def handle_continue(true, %{file: file} = s) do
    Logger.debug(
      "#{inspect(__MODULE__)} file:#{inspect(file)} content:#{inspect(read_shadow(file))}}"
    )

    {:noreply, %{s | shadow: read_shadow(file)}}
  end

  def handle_continue(false, %{file: file} = s) do
    dirname = Path.dirname(file)
    Logger.debug("#{inspect(__MODULE__)} file:#{inspect(file)} ")

    with :ok <- File.mkdir_p(dirname),
         :ok <- write_shadow(file, "") do
      {:noreply, %{s | shadow: ""}}
    else
      _ ->
        {:noreply, %{s | file: nil}}
    end
  end

  def handle_call(:get_shadow, _from, %{shadow: shadow} = s) do
    {:reply, shadow, s}
  end
  def handle_call({:update_shadow, :reported, fun}, _from, %{shadow: shadow, file: file} = s) do
    client_id = Adapter.client_id()

    Logger.debug("#{inspect(__MODULE__)} #{inspect(shadow)}")
    reported =
      with {:ok, reported} <- get_reported_object(shadow) do
        fun.(reported)
      else
        _ ->
        fun.(%{})
      end

    {:ok, timer_ref} = :timer.send_after(30_000, self(), :send_reported)
    {:reply, :ok, Map.put(s, :shadow_reported, reported)}
  end

  def handle_call(:request_upstream, _from, s) do
    subscribe()
    client_id = Adapter.client_id()
    topic = "$aws/things/#{client_id}/shadow/get"

    if Adapter.connected?() do
      Logger.info("shadow requested #{inspect(topic)}")
      Adapter.publish(topic, <<>>, qos: 0)
      {:reply, :ok, %{s | upstream_requested?: true}}
    else
      {:reply, :not_connected, s}
    end
  end

  def handle_info(:request_upstream, %{upstream_requested?: false} = s) do
    subscribe()
    Logger.info("requesting shadow")
    client_id = Adapter.client_id()
    topic = "$aws/things/#{client_id}/shadow/get"

    if Adapter.connected?() do
      Adapter.publish(topic, <<>>, qos: 0)
      {:noreply, %{s | upstream_requested?: true}}
    else
      send(self(), :request_upstream)
      {:noreply, s}
    end
  end

  def handle_info(:send_reported,s) do
    client_id = Adapter.client_id()
    topic = "$aws/things/#{client_id}/shadow/update"
    Logger.debug("#{inspect(__MODULE__)} send_reported #{inspect(byte_size(Jason.encode!(s.shadow_reported)))}, topic:#{inspect(topic)}}")

    result = Adapter.publish(topic, Jason.encode!(s.shadow_reported), qos: 0)
    Logger.debug("#{inspect(__MODULE__)} send_reported #{inspect(result)}")
    {:noreply, s}
  end

  def handle_call({:update_shadow, fun}, _from, %{shadow: shadow, file: file} = s) do
    Logger.debug("#{inspect(__MODULE__)} #{inspect(shadow)}")
    shadow = fun.(shadow)
    write_shadow(file, shadow)
    {:reply, :ok, %{s | shadow: shadow}}
  end

  def handle_info({:aws_iot, topic, payload}, s) do
    Logger.debug("[shadow] aws_iot topic:#{inspect(topic)} payload:#{inspect(payload)} ")
    [_, command] = String.split(topic, "shadow/", parts: 2)

    handle_upstream(command, payload, s)
  end

  def handle_upstream("get", payload, s) do
    :noop
    {:noreply, s}
  end

  def handle_upstream(_cmd, payload, s) do
    shadow = Jason.decode!(payload)
    write_shadow(s.file, shadow)
    {:noreply, %{s | shadow: shadow}}
  end

  defp read_shadow(file) do
    with {:ok, data} <- File.read(file) do
      :erlang.binary_to_term(data)
    else
      _ ->
        %{}
    end
  end

  defp write_shadow(nil, _shadow), do: {:error, :no_file}

  defp write_shadow(file, shadow) do
    data = :erlang.term_to_binary(shadow)
    File.write(file, data, [:write, :sync])
  end

  defp path(nil), do: System.tmp_dir!()
  defp path(path), do: Path.expand(path)

  defp subscribe() do
    topics = topics(Adapter.client_id())

    with true <- Adapter.connected?() do
      Enum.each(topics, fn item ->
        Router.subscribe(item)
      end)
    else
      error ->
        :error
    end
  end


  def get_reported_object(%{"state" => %{"reported" => reported}}) do
    {:ok, reported}
  end
  def get_reported_object("") do
     {:ok, %{}}
  end
  def get_reported_object(_x) do
    {:error, :no_match}
  end


  def topics(client_id) do
    [
      "$aws/things/#{client_id}/shadow/update",
      "$aws/things/#{client_id}/shadow/get",
      "$aws/things/#{client_id}/shadow/get/accepted",
      "$aws/things/#{client_id}/shadow/get/rejected",
      "$aws/things/#{client_id}/shadow/update/accepted",
    ]
  end
end
