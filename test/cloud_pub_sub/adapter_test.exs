defmodule CloudPubSub.Adapter.Mock do
  @behaviour CloudPubSub.Adapter

  @impl CloudPubSub.Adapter
  def connected?(state), do: {false, state}

  @impl CloudPubSub.Adapter
  def publish(_topic, _payload, opts, state), do: {opts, state}

  @impl CloudPubSub.Adapter
  def subscribe(_topic, _opts, state), do: {false, state}

  def init(opts) do
    {:ok, opts}
  end
end

defmodule CloudPubSub.AdapterTest do
  use ExUnit.Case
  alias CloudPubSub.Adapter

  setup do
    Application.put_env(:cloud_pub_sub, :adapter, CloudPubSub.Adapter.Mock)
  end

  describe "init/1" do
    test "adds a default value for sni" do
      opts = [
        client_id: "test",
        cloud_provider: :aws,
        host: "test"
      ]

      {:ok, %{adapter_state: adapter_state}} = Adapter.init(opts)
      assert Keyword.has_key?(adapter_state, :server_name_indication)
    end

    test "allows override for sni" do
      opts = [
        client_id: "test",
        cloud_provider: :aws,
        host: "test"
      ]

      {:ok, %{adapter_state: default_opt}} = Adapter.init(opts)

      {:ok, %{adapter_state: custom_opt}} =
        opts
        |> Keyword.merge(server_name_indication: "test")
        |> Adapter.init()

      refute custom_opt[:server_name_indication] == default_opt[:server_name_indication]
    end
  end
end
