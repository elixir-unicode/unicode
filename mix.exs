defmodule Unicode.MixProject do
  use Mix.Project

  @version "1.13.1"

  def project do
    [
      app: :unicode,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Unicode",
      source_url: "https://github.com/elixir-unicode/unicode",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: ~w(mix inets public_key)a,
        ignore_warnings: ".dialyzer_ignore_warnings"
      ]
    ]
  end

  defp description do
    """
    Functions to introspect the Unicode character database and
    to provide fast codepoint lookups and guards.
    """
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      logo: "logo.png",
      links: links(),
      files: [
        "lib",
        "data",
        "config",
        "logo.png",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key, :inets]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev, optional: true},
      {:ex_doc, "~> 0.24", only: [:dev, :release], runtime: false, optional: true},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false, optional: true}
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-unicode/unicode",
      "Readme" => "https://github.com/elixir-unicode/unicode/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/elixir-unicode/unicode/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logo.png",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "src", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix", "src", "bench"]
  defp elixirc_paths(_), do: ["lib", "src"]
end
