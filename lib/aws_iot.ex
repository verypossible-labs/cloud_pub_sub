defmodule AWSIoT do
  @moduledoc """
  An abstraction over AWS IoT Core.
  """

  @cacerts File.ls!("cacerts")
           |> Enum.map(&Path.join("cacerts", &1))
           |> Enum.map(&Path.expand/1)
           |> Enum.map(&File.read!/1)
           |> Enum.map(&X509.Certificate.from_pem!/1)
           |> Enum.map(&X509.Certificate.to_der/1)

  @doc """
  Return AWS CA certificates.

  Reference https://www.amazontrust.com/repository/.
  """
  def cacerts(), do: @cacerts

  defdelegate connected?(), to: AWSIoT.Adapter

  defdelegate publish(topic, payload, opts), to: AWSIoT.Adapter
  defdelegate subscribe(topic, opts \\ []), to: AWSIoT.Adapter

  @doc """
  Return the official AWS topic associated with the `short_name` using `client_id`.
  """
  def topic(short_name, client_id)
  def topic(:shadow_update, client_id), do: "$aws/things/#{client_id}/shadow/update"
  def topic(:shadow_get, client_id), do: "$aws/things/#{client_id}/shadow/get"
  def topic(:shadow_get_accepted, client_id), do: "$aws/things/#{client_id}/shadow/get/accepted"
  def topic(:shadow_get_rejected, client_id), do: "$aws/things/#{client_id}/shadow/get/rejected"
end
