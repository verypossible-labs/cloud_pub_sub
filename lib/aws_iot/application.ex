defmodule AWSIoT.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = Application.get_all_env(:aws_iot)

    shadow_opts =
      Application.get_env(:aws_iot, :shadow, [])
      |> Keyword.put(:name, AWSIoT.Shadow)

    children = [
      # Starts a worker by calling: AWSIoT.Worker.start_link(arg)
      AWSIoT.Router,
      {AWSIoT.Adapter, opts},
      {AWSIoT.Shadow, shadow_opts}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AWSIoT.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
