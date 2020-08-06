defmodule CloudPubSub.Adapters.Tortoise.SSL do
  use CloudPubSub.Adapters.Tortoise

  def init(opts) do
    opts[:device_cert] || raise "AWS IoT requires a :device_cert."
    opts[:device_key] || raise "AWS IoT requires a :device_key."
    opts[:signer_cert] || raise "AWS IoT requires a :signer_cert."

    server =
      {Tortoise.Transport.SSL,
       [
         alpn_advertised_protocols: ["x-amzn-mqtt-ca"],
         cacerts: [opts[:signer_cert] | opts[:aws_ca_certs]],
         cert: opts[:device_cert],
         host: opts[:host],
         key: opts[:device_key],
         partial_chain: &CloudPubSub.SSL.partial_chain/1,
         port: opts[:port],
         server_name_indication: opts[:server_name_indication],
         verify: :verify_peer,
         versions: [:"tlsv1.2"]
       ]}

    CloudPubSub.Adapters.Tortoise.tortoise_connect(opts[:client_id], opts[:subscriptions], server)
    {:ok, %{client_id: opts[:client_id]}}
  end
end
