defmodule AWSIoT.ShadowTest do
  use ExUnit.Case
  doctest AWSIoT.Shadow
  alias AWSIoT.Shadow

  @client_id Application.get_env(:aws_iot, :client_id)

  setup context do
    path = Path.join([File.cwd!(), "test", "tmp", "shadow"])
    filename = to_string(context.test)
    {:ok, pid} = Shadow.start_link(filename: filename, path: path)
    [pid: pid, shadow_file: Path.join(path, filename)]
  end

  test "create shadow file", %{pid: pid, shadow_file: file} do
    Shadow.update_shadow(pid, fn _shadow ->
      %{"foo" => "bar"}
    end)

    assert File.exists?(file)
  end

  test "update shadow", %{pid: pid} do
    Shadow.update_shadow(pid, fn _shadow ->
      %{"foo" => "bar"}
    end)

    Shadow.update_shadow(pid, fn shadow ->
      Map.put(shadow, "baz", "qux")
    end)

    assert %{"foo" => "bar", "baz" => "qux"} = Shadow.get_shadow(pid)
  end

  test "get shadow", %{pid: pid} do
    assert "" = Shadow.get_shadow(pid)

    Shadow.update_shadow(pid, fn _shadow ->
      %{"foo" => "bar"}
    end)

    assert %{"foo" => "bar"} = Shadow.get_shadow(pid)
  end

  test "update from server", %{pid: pid} do
    shadow = %{"foo" => "bar"}
    send(pid, {:aws_iot, "$aws/things/#{@client_id}/shadow/update", Jason.encode!(shadow)})
    assert ^shadow = Shadow.get_shadow(pid)
  end
end
