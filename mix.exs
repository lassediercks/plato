defmodule Plato.MixProject do
  use Mix.Project

  def project do
    [
      app: :plato,
      # x-release-please-start-version
      version: "0.0.23",
      # x-release-please-end
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/lassediercks/plato",
      homepage_url: "https://github.com/lassediercks/plato",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.lcov": :test
      ]
    ] ++ listeners()
  end

  defp listeners do
    if Mix.env() in [:dev, :test] do
      [listeners: [Phoenix.CodeReloader]]
    else
      []
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Plato.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.13.4"},
      {:postgrex, "~> 0.19"},
      {:phoenix, "~> 1.8.3"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1.22"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.0", only: :test},
      # Optional dependencies for image field support
      {:ex_aws, "~> 2.5", optional: true},
      {:ex_aws_s3, "~> 2.5", optional: true},
      {:hackney, "~> 1.20", optional: true}
    ]
  end

  defp description do
    """
    A schema-driven headless CMS for Phoenix applications.
    Create dynamic content types, manage relationships, and query content
    with a clean API. Includes a mountable admin UI for content management.
    """
  end

  defp package do
    [
      name: "plato",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/lassediercks/plato"
      },
      maintainers: ["Lasse Diercks"],
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      # x-release-please-start-version
      source_ref: "v0.0.23",
      # x-release-please-end
      source_url: "https://github.com/lassediercks/plato",
      groups_for_extras: [
        Project: ["README.md", "CHANGELOG.md", "LICENSE"]
      ]
    ]
  end
end
