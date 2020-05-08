defmodule AWSIoT.ShadowTest do
  use ExUnit.Case
  doctest AWSIoT.Shadow
  alias AWSIoT.Shadow

  setup context do
    path = Path.join([File.cwd!(), "test", "tmp", "shadow"])
    filename = to_string(context.test)
    {:ok, pid} = Shadow.start_link(shadow_filename: filename, shadow_path: path)
    [pid: pid, shadow_file: Path.join(path, filename)]
  end

  test "create shadow file", %{pid: pid, shadow_file: file} do
    Shadow.update_shadow(pid, fn _shadow ->
      %{foo: :bar}
    end)

    assert File.exists?(file)
  end

  test "update shadow", %{pid: pid, shadow_file: file} do
    Shadow.update_shadow(pid, fn _shadow ->
      %{foo: :bar}
    end)

    assert File.exists?(file)

    Shadow.update_shadow(pid, fn shadow ->
      Map.put(shadow, :baz, :qux)
    end)

    assert %{foo: :bar, baz: :qux} = Shadow.get_shadow(pid)
  end

  test "get shadow", %{pid: pid} do
    assert "" = Shadow.get_shadow(pid)

    Shadow.update_shadow(pid, fn _shadow ->
      %{foo: :bar}
    end)

    assert %{foo: :bar} = Shadow.get_shadow(pid)
  end
end
