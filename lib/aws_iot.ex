defmodule AWSIoT do
  cacerts =
    File.ls!("cacerts")
    |> Enum.map(&Path.join("cacerts", &1))
    |> Enum.map(&Path.expand/1)
    |> Enum.map(&File.read!/1)
    |> Enum.map(&X509.Certificate.from_pem!/1)
    |> Enum.map(&X509.Certificate.to_der/1)

  @cacerts cacerts

  def cacerts(), do: @cacerts
  def cacerts(signer_cert), do: [signer_cert | @cacerts]

  defdelegate connected?(), to: AWSIoT.Adapter
  defdelegate publish(topic, payload, opts), to: AWSIoT.Adapter

  def topic(:shadow_update, client_id), do: "$aws/things/#{client_id}/shadow/update"
  def topic(:shadow_get, client_id), do: "$aws/things/#{client_id}/shadow/get"
  def topic(:shadow_get_accepted, client_id), do: "$aws/things/#{client_id}/shadow/get/accepted"
  def topic(:shadow_get_rejected, client_id), do: "$aws/things/#{client_id}/shadow/get/rejected"
end
