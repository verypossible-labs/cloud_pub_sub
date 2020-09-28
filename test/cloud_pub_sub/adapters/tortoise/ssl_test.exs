defmodule CloudPubSub.Adapters.Tortoise.SSLTest do
  use ExUnit.Case
  alias CloudPubSub.Adapters.Tortoise.SSL

  describe "resolve_connection_opts/1" do
    test "AWS" do
      opts = [
        cloud_provider: :aws,
        signer_cert: "der-binary-1",
        device_cert: "der-binary-2",
        device_key: "device-key",
        client_id: "device-id",
        host: "aws-ats-endpoint",
        port: 123,
        subscriptions: ["sub"]
      ]

      expected_except_server = %{
        client_id: "device-id",
        cloud_provider: :aws,
        handler: nil,
        subscriptions: ["sub"]
      }

      actual = SSL.resolve_connection_opts(opts)
      assert expected_except_server == Map.delete(actual, :server)
      assert {Tortoise.Transport.SSL, actual_server_opts} = actual.server
      assert is_function(actual_server_opts[:partial_chain])
      assert :verify_peer == actual_server_opts[:verify]
      assert [:"tlsv1.2"] == actual_server_opts[:versions]
      assert "aws-ats-endpoint" == actual_server_opts[:host]
      assert ["der-binary-1"] == actual_server_opts[:cacerts]
      assert "der-binary-2" == actual_server_opts[:cert]
      assert "device-key" == actual_server_opts[:key]
      assert 123 == actual_server_opts[:port]
    end

    test "GCP" do
      opts = [
        client_id:
          "projects/project-name/locations/us-central1/registries/registry-name/devices/device-id",
        cloud_provider: :gcp,
        host: "mqtt.googleapis.com",
        password: "jwt",
        port: 123,
        subscriptions: ["sub"],
        username: "unused"
      ]

      expected_except_server = %{
        client_id:
          "projects/project-name/locations/us-central1/registries/registry-name/devices/device-id",
        cloud_provider: :gcp,
        handler: nil,
        password: "jwt",
        subscriptions: ["sub"]
      }

      actual = SSL.resolve_connection_opts(opts)
      assert expected_except_server == Map.delete(actual, :server)
      assert {Tortoise.Transport.SSL, actual_server_opts} = actual.server
      assert is_function(actual_server_opts[:partial_chain])
      assert :verify_peer == actual_server_opts[:verify]
      assert [:"tlsv1.2"] == actual_server_opts[:versions]
      assert "mqtt.googleapis.com" == actual_server_opts[:host]
      assert 123 == actual_server_opts[:port]
    end
  end
end
