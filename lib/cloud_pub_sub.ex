defmodule CloudPubSub do
  @moduledoc """
  An abstraction over AWS IoT Core and GCP Cloud IOT Core.
  """

  @aws_ca_certs Path.join([:code.priv_dir(:cloud_pub_sub), "ca_certs", "aws"])
                |> File.ls!()
                |> Stream.map(&Path.join([:code.priv_dir(:cloud_pub_sub), "ca_certs", "aws", &1]))
                |> Stream.map(&Path.expand/1)
                |> Stream.map(&File.read!/1)
                |> Stream.map(&X509.Certificate.from_pem!/1)
                |> Enum.map(&X509.Certificate.to_der/1)

  @gcp_ca_certs Path.join([:code.priv_dir(:cloud_pub_sub), "ca_certs", "gcp"])
                |> File.ls!()
                |> Stream.map(&Path.join([:code.priv_dir(:cloud_pub_sub), "ca_certs", "gcp", &1]))
                |> Stream.map(&Path.expand/1)
                |> Stream.map(&File.read!/1)
                |> Stream.map(&X509.Certificate.from_pem!/1)
                |> Enum.map(&X509.Certificate.to_der/1)

  @doc """
  Return AWS CA certificates.

  Reference https://www.amazontrust.com/repository/.
  """
  def ca_certs(:aws), do: @aws_ca_certs

  def ca_certs(:gcp), do: @gcp_ca_certs

  defdelegate connected?(), to: CloudPubSub.Adapter

  defdelegate publish(topic, payload, opts), to: CloudPubSub.Adapter
  defdelegate subscribe(topic, opts \\ []), to: CloudPubSub.Adapter

  @doc """
  Return the official AWS topic associated with the `short_name` using `client_id`.
  """
  def topic(short_name, client_id)
  def topic(:shadow_update, client_id), do: "$aws/things/#{client_id}/shadow/update"
  def topic(:shadow_get, client_id), do: "$aws/things/#{client_id}/shadow/get"
  def topic(:shadow_get_accepted, client_id), do: "$aws/things/#{client_id}/shadow/get/accepted"
  def topic(:shadow_get_rejected, client_id), do: "$aws/things/#{client_id}/shadow/get/rejected"
end
