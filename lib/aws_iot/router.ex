defmodule AWSIoT.Router do
  use GenServer

  alias AWSIoT.Adapter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(topic) do
    GenServer.call(__MODULE__, {:subscribe, topic})
  end

  def unsubscribe(topic) do
    GenServer.call(__MODULE__, {:subscribe, topic})
  end

  def init(_opts) do
    {:ok,
     %{
       subscribers: []
     }}
  end

  def handle_call({:subscribe, topic}, {pid, _ref}, s) do
    subscribers =
      case Enum.member?(s.subscribers, {pid, topic}) do
        true ->
          s.subscribers

        false ->
          Adapter.subscribe(topic)
          mon_ref = Process.monitor(pid)
          [{pid, mon_ref, topic} | s.subscribers]
      end

    {:reply, :ok, %{s | subscribers: subscribers}}
  end

  def handle_info({:message, topic, payload}, s) do
    broadcast_messages(topic, payload, s.subscribers)
    {:noreply, s}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, s) do
    {down, subscribers} =
      Enum.split_with(s.subscribers, fn {_, p_ref, _} ->
        p_ref == ref
      end)

    case down do
      [] ->
        :noop

      [{_, _, topic}] ->
        cleanup_subscriptions(topic, subscribers)
    end

    {:noreply, %{s | subscribers: subscribers}}
  end

  defp broadcast_messages(topic, payload, subscribers) do
    Enum.each(subscribers, fn
      {pid, _, ^topic} ->
        send(pid, {:aws_iot, topic, payload})

      _ ->
        :noop
    end)
  end

  defp cleanup_subscriptions(topic, subscribers) do
    retain? = Enum.any?(subscribers, fn {_, _, s_topic} -> s_topic == topic end)

    unless retain? do
      Adapter.unsubscribe(topic)
    end
  end
end
