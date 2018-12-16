defmodule Bip32.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bip32,
      version: "0.1.0",
      description: "Bitcoin HD Wallets BIP32 Elixir implementation",
      package: package(),
      elixir: "~> 1.7.4",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      maintainers: [" wuminzhe "],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wuminzhe/bip32"}
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
    []
  end
end
