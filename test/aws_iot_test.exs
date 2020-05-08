defmodule AWSIoTTest do
  use ExUnit.Case
  doctest AWSIoT

  alias AWSIoT.Shadow

  # test "connected?" do
  #   assert AWSIoT.connected?() == false
  #   set_connected(true)
  #   assert AWSIoT.connected?() == true
  # end

  # defp set_connected(connected) do
  #   :sys.replace_state(AWSIoT.Adapter, fn {mod, state} ->
  #     {mod, %{state | connected?: connected}}
  #   end)
  # end
end
