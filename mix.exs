defmodule CloudPubSub.MixProject do
  use Mix.Project

  def project do
    [
      app: :cloud_pub_sub,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tortoise311, "~> 0.11"},
      {:x509, "~> 0.8"}
    ]
  end
end
