defmodule CloudPubSub.SSL do
  alias X509.Certificate

  def partial_chain(cloud_provider, server_certs) do
    Enum.reduce_while(CloudPubSub.ca_certs(cloud_provider), :unknown_ca, fn aws_root_ca, unk_ca ->
      certificate = aws_root_ca |> Certificate.from_der!()
      certificate_subject = Certificate.extension(certificate, :subject_key_identifier)

      case find_partial_chain(certificate_subject, server_certs) do
        {:trusted_ca, _} = result -> {:halt, result}
        :unknown_ca -> {:cont, unk_ca}
      end
    end)
  end

  defp find_partial_chain(_root_subject, []) do
    :unknown_ca
  end

  defp find_partial_chain(root_subject, [h | t]) do
    cert = Certificate.from_der!(h)
    cert_ski = Certificate.extension(cert, :subject_key_identifier)
    cert_aki = Certificate.extension(cert, :ancestor_key_identifier)

    if root_subject in [cert_ski, cert_aki] do
      {:trusted_ca, h}
    else
      find_partial_chain(root_subject, t)
    end
  end
end
