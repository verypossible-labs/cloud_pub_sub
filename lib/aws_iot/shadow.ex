defmodule AWSIoT.Shadow do
  use GenServer

  alias AWSIoT.{Adapter, Router}

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

  def genserver_opts(opts) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} -> [name: name]
      _ -> []
    end
  end

  def init(opts) do
    filename = opts[:filename] || @filename
    file = Path.join(path(opts[:path]), filename)

    {:ok,
     %{
       file: file,
       shadow: nil
     }, {:continue, File.exists?(file)}}
  end

  def handle_continue(true, %{file: file} = s) do
    subscribe()
    {:noreply, %{s | shadow: read_shadow(file)}}
  end

  def handle_continue(false, %{file: file} = s) do
    subscribe()
    dirname = Path.dirname(file)

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

  def handle_call({:update_shadow, fun}, _from, %{shadow: shadow, file: file} = s) do
    shadow = fun.(shadow)
    write_shadow(file, shadow)
    {:reply, :ok, %{s | shadow: shadow}}
  end

  def handle_info({:aws_iot, topic, payload}, s) do
    [_, command] = String.split(topic, "shadow/", parts: 2)
    handle_upstream(command, payload, s)
  end

  def handle_upstream("update", payload, s) do
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
    Adapter.client_id()
    |> topics()
    |> Enum.each(&Router.subscribe/1)
  end

  def topics(client_id) do
    [
      "$aws/things/#{client_id}/shadow/update",
      "$aws/things/#{client_id}/shadow/get",
      "$aws/things/#{client_id}/shadow/get/accepted",
      "$aws/things/#{client_id}/shadow/get/rejected"
    ]
  end
end
