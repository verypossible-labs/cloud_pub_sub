defmodule AWSIoTTest.Adapter do
  @behaviour AWSIoT.Adapter

  def init(_opts) do
    {:ok,
     %{
       connected?: false
     }}
  end

  def connected?(%{connected?: connected?}) do
    connected?
  end

  def publish(_topic, _payload, _opts, _client_id) do
    :ok
  end
end
