defmodule AWSIoT.Shadow do
  use GenServer

  @shadow_filename "aws_iot_shadow.json"

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
    filename = opts[:shadow_filename] || @shadow_filename
    shadow_file = Path.join(path(opts[:shadow_path]), filename)

    {:ok,
     %{
       shadow_file: shadow_file,
       shadow: nil
     }, {:continue, File.exists?(shadow_file)}}
  end

  def handle_continue(true, %{shadow_file: file} = s) do
    {:noreply, %{s | shadow: read_shadow(file)}}
  end

  def handle_continue(false, %{shadow_file: file} = s) do
    dirname = Path.dirname(file)

    with :ok <- File.mkdir_p(dirname),
         :ok <- write_shadow(file, "") do
      {:noreply, %{s | shadow: ""}}
    else
      _ ->
        {:noreply, %{s | shadow_file: nil}}
    end
  end

  def handle_call(:get_shadow, _from, %{shadow: shadow} = s) do
    {:reply, shadow, s}
  end

  def handle_call({:update_shadow, fun}, _from, %{shadow: shadow, shadow_file: file} = s) do
    shadow = fun.(shadow)
    write_shadow(file, shadow)
    {:reply, :ok, %{s | shadow: shadow}}
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
end
