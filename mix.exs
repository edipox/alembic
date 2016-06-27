defmodule Alembic.Mixfile do
  use Mix.Project

  # Functions

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  def project do
    [
      app: :alembic,
      build_embedded: Mix.env == :prod,
      deps: deps,
      elixir: "~> 1.2",
      name: "Alembic",
      start_permanent: Mix.env == :prod,
      version: "2.1.1"
    ]
  end

  ## Private Functions

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # success type checker: ensures @type and @spec are valid
      {:dialyze, "~> 0.2.1", only: [:dev, :test]}
    ]
  end
end
