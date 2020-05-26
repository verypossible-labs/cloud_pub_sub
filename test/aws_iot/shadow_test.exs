defmodule AWSIoT.ShadowTest do
  use ExUnit.Case
  doctest AWSIoT.Shadow
  alias AWSIoT.Shadow

  @client_id Application.get_env(:aws_iot, :client_id)
  @shadow_sample = %{
    "metadata" => %{
      "desired" => %{
        "requested_tags" => [
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906},
          %{"timestamp" => 1_589_913_906}
        ],
        "welcome" => %{"timestamp" => 1_589_913_906}
      },
      "reported" => %{"welcome" => %{"timestamp" => 1_589_913_906}}
    },
    "state" => %{
      "delta" => %{
        "requested_tags" => [
          "Machine_Run_Not_Jog",
          "JAM_LATCH",
          "ANVIL_THICKNESS",
          "ANVIL_KNIFE_DEPTH",
          "GRIND_ENABLED_ONS",
          "FIND_CVR_START",
          "GRIND_HMI_OVRD_VALUE",
          "Single_Feed_Latch",
          "Board_Count_Total",
          "MACH_SPD_ACTUAL_RPM_REAL",
          "P1_INK_BOOL_ARRAY0_4",
          "P1_INK_BOOL_ARRAY0_8",
          "All_EStops_OK_to_Run",
          "ANVIL_COMP_ConverterOutputCurrent",
          "P1_HMI_INK_DINT_ARRAY3",
          "FEED_REQUEST_SEALED",
          "FE_GUIDE_REAL_ARRAY_OS",
          "FE_GUIDE_REAL_ARRAY_DS",
          "Sunset_Current_Feed_BackStop_Target"
        ]
      },
      "desired" => %{
        "requested_tags" => [
          "Machine_Run_Not_Jog",
          "JAM_LATCH",
          "ANVIL_THICKNESS",
          "ANVIL_KNIFE_DEPTH",
          "GRIND_ENABLED_ONS",
          "FIND_CVR_START",
          "GRIND_HMI_OVRD_VALUE",
          "Single_Feed_Latch",
          "Board_Count_Total",
          "MACH_SPD_ACTUAL_RPM_REAL",
          "P1_INK_BOOL_ARRAY0_4",
          "P1_INK_BOOL_ARRAY0_8",
          "All_EStops_OK_to_Run",
          "ANVIL_COMP_ConverterOutputCurrent",
          "P1_HMI_INK_DINT_ARRAY3",
          "FEED_REQUEST_SEALED",
          "FE_GUIDE_REAL_ARRAY_OS",
          "FE_GUIDE_REAL_ARRAY_DS",
          "Sunset_Current_Feed_BackStop_Target"
        ],
        "welcome" => "aws-iot"
      },
      "reported" => %{"welcome" => "aws-iot"}
    },
    "timestamp" => 1_590_002_257,
    "version" => 32
  }

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

  test "decode shadow object", %{pid: pid} do
  end

  test "update from server", %{pid: pid} do
    shadow = %{"foo" => "bar"}
    send(pid, {:aws_iot, "$aws/things/#{@client_id}/shadow/update", Jason.encode!(shadow)})
    assert ^shadow = Shadow.get_shadow(pid)
  end
end
