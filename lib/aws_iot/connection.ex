defmodule AWSIoT.Connection do
  @doc """
  Delegates to `Tortoise.Supervisor.start_child/1`.
  """
  def start_child(opts) do
    opts = default_opts(opts)

    Tortoise.Supervisor.start_child(
      client_id: opts[:client_id],
      handler: {AWSIoT, []},
      server: {
        Tortoise.Transport.SSL,
        alpn_advertised_protocols: ["x-amzn-mqtt-ca"],
        cacerts: (opts[:cacerts]),
        cert: opts[:cert],
        host: opts[:host],
        key: opts[:key],
        partial_chain: &partial_chain/1,
        port: opts[:port],
        server_name_indication: opts[:server_name_indication],
        verify: :verify_peer,
        versions: [:"tlsv1.2"]
      },
      subscriptions: opts[:subscriptions]
    )
  end

  def default_opts(opts) do
    opts[:host] || raise """
    AWS IoT requires a :host. You can find this information in the AWS console.
    """
    client_id = opts[:client_id] || raise """
    AWS IoT requires a client id to be set to the same value as the serial number.
    """

    signer = Keyword.get(opts, :signer_cert, [])
    opts
    |> Keyword.put_new(:port, 443)
    |> Keyword.put_new(:server_name_indication, '*.iot.us-east-1.amazonaws.com')
    |> Keyword.put_new(:cacerts, [signer | AWSIoT.cacerts()])
    |> Keyword.put_new(:subscriptions, [
      {AWSIoT.topic(:shadow_get_accepted, client_id), 1},
      {AWSIoT.topic(:shadow_get_rejected, client_id), 1}
    ])
  end

  require Logger
  defp partial_chain(server_certs) do
    Logger.debug("Do all the things!")
    result = Enum.reduce_while(AWSIoT.cacerts(), :unknown_ca, fn aws_root_ca, unk_ca ->
      Logger.debug("Do the thing!")
      certificate = aws_root_ca |> X509.Certificate.from_der!()
      certificate_subject = X509.Certificate.extension(certificate, :subject_key_identifier)

      case find_partial_chain(certificate_subject, server_certs) do
        {:trusted_ca, _} = result -> {:halt, result}
        :unknown_ca -> {:cont, unk_ca}
      end
    end)
    Logger.debug("Result: #{inspect result}")
    result
  end

  defp find_partial_chain(_root_subject, []) do
    :unknown_ca
  end

  defp find_partial_chain(root_subject, [h | t]) do
    cert = X509.Certificate.from_der!(h)
    cert_subject = X509.Certificate.extension(cert, :subject_key_identifier)
    Logger.debug "Root Subj Key: #{inspect root_subject}"
    Logger.debug "Server Subj Key: #{inspect cert_subject}"
    if cert_subject == root_subject do
      {:trusted_ca, h}
    else
      find_partial_chain(root_subject, t)
    end
  end
end
