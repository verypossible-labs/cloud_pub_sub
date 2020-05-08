defmodule AWSIoTTest.Adapter do
  @behaviour AWSIoT.Adapter

  def init(_opts) do
    {:ok,
     %{
       subscriptions: [],
       connected?: false
     }}
  end

  def connected?(%{connected?: connected?}) do
    connected?
  end

  def publish(_topic, _payload, _opts, s) do
    {:ok, s}
  end

  def subscribe(topic, _opts, s) do
    {:ok, %{s | subscriptions: [topic | s.subscriptions]}}
  end

  def unsubscribe(topic, _opts, s) do
    {_, subscriptions} = Enum.split_with(s.subscriptions, &(&1 == topic))
    {:ok, %{s | subscriptions: subscriptions}}
  end
end
