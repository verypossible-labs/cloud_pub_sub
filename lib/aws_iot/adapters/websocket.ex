defmodule AWSIoT.Adapters.Websocket do
  @behaviour AWSIoT.Adapter

  alias AWSIoT.Adapters.Websocket.Handler

  require Logger

  def init(opts) do
    host = opts[:host]
    config = ExAws.Config.new(:iot)
    {:ok, signed_url} = sigv4_url(host, config)
    Logger.debug "Signed URL: #{inspect signed_url}"
    Logger.debug "AWS Config: #{inspect config}"
    {:ok, socket} =
      :websocket_client.start_link(
        String.to_charlist(signed_url),
        Handler,
        opts,
        opts
      )
    {:ok, %{
      opts: opts,
      config: config,
      socket: socket
    }}
  end

  def connected?(_) do
    :not_implemented
  end

  def publish(_, _, _, _) do
    :not_implemented
  end

  defp sigv4_url(host, config) do
    service = :iotdevicegateway
    url = "wss://#{host}/mqtt"
    method = :get
    expires = 86400
    datetime = :erlang.universaltime()
    ExAws.Auth.presigned_url(method, url, service, datetime, config, expires)
  end
end
