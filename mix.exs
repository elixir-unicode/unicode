defmodule Cldr.Unicode.MixProject do
  use Mix.Project

  @version "0.8.0"

  def project do
    [
      app: :ex_cldr_unicode,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Cldr Unicode",
      source_url: "https://github.com/elixir-cldr/cldr_unicode",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp description do
    """
    DEPRECATED. Package replaced by `ex_unicode`, please use that package. Functions to introspect the Unicode character database and
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 0.14", only: :dev},
      {:ex_doc, "~> 0.18", only: [:release, :dev]}
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_unicode",
      "Readme" => "https://github.com/elixir-cldr/cldr_unicode/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/elixir-cldr/cldr_unicode/blob/v#{@version}/CHANGELOG.md",
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
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "src", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix", "src", "bench"]
  defp elixirc_paths(_), do: ["lib", "src"]
end
