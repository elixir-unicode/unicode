defmodule Unicode.MixProject do
  use Mix.Project

  @version "2.2.0"

  def project do
    [
      app: :unicode,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Unicode",
      source_url: "https://github.com/elixir-unicode/unicode",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        summary: [threshold: 90],
        ignore_modules: coverage_ignore_modules()
      ],
      dialyzer: [
        plt_add_apps: ~w(mix inets public_key)a,
        ignore_warnings: ".dialyzer_ignore_warnings"
      ]
    ]
  end

  # Modules excluded from `mix test --cover` measurement so the
  # coverage number reflects the runtime library, not build tooling:
  #
  # * `Mix.Tasks.*` — the Unicode data download task, run at build
  #   time, never at library runtime.
  #
  # * Test support modules under `test/support` — test harness code.
  #
  # * `Unicode.DerivedCategory.Printable` — a compile-time data holder whose
  #   only function is evaluated while building a module attribute, so it is
  #   never called at runtime.
  defp coverage_ignore_modules do
    [
      ~r/^Mix\.Tasks\./,
      Unicode.Validation.UTF8.Test.Helpers,
      Unicode.DerivedCategory.Printable
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
      licenses: ["Apache-2.0"],
      logo: "logo.png",
      links: links(),
      files: [
        "lib",
        "data",
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
      extra_applications: [:logger, :public_key, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev, optional: true},
      {:ex_doc, "~> 0.24", only: [:dev, :release], runtime: false, optional: true},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false, optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false, optional: true}
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
        "guides/introduction.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Guides: Path.wildcard("guides/*.md")
      ],
      groups_for_modules: groups_for_modules(),
      formatters: ["html", "markdown"],
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md"]
    ]
  end

  # `Unicode` is the entry point and stays at the top level; every other documented module is
  # grouped so that nothing lands in ExDoc's ungrouped catch-all. `test/docs_test.exs` asserts the
  # lists stay complete, so a module added in a later release fails a test rather than quietly
  # appearing at the bottom of the sidebar.
  defp groups_for_modules do
    [
      "Character properties": [
        Unicode.Age,
        Unicode.Block,
        Unicode.CanonicalCombiningClass,
        Unicode.DecompositionType,
        Unicode.EastAsianWidth,
        Unicode.GeneralCategory,
        Unicode.HangulSyllableType,
        Unicode.NumericType,
        Unicode.NumericValue,
        Unicode.Property,
        Unicode.Script,
        Unicode.ScriptExtensions,
        Unicode.VerticalOrientation
      ],
      "Bidirectional and shaping": [
        Unicode.BidiClass,
        Unicode.BidiPairedBracketType,
        Unicode.JoiningGroup,
        Unicode.JoiningType
      ],
      Segmentation: [
        Unicode.GraphemeClusterBreak,
        Unicode.LineBreak,
        Unicode.SentenceBreak,
        Unicode.WordBreak
      ],
      "Indic properties": [
        Unicode.IndicConjunctBreak,
        Unicode.IndicPositionalCategory,
        Unicode.IndicSyllabicCategory
      ],
      Normalization: [
        Unicode.NfcQuickCheck,
        Unicode.NfdQuickCheck,
        Unicode.NfkcQuickCheck,
        Unicode.NfkdQuickCheck
      ],
      "Character names": [
        Unicode.CharacterName
      ],
      "Link detection": [
        Unicode.LinkBracket,
        Unicode.LinkEmail,
        Unicode.LinkTerm
      ],
      Guards: [
        Unicode.Guards
      ],
      Internals: [
        Unicode.Category.QuoteMarks,
        Unicode.GeneralCategory.Derived,
        Unicode.Property.Behaviour,
        Unicode.RangeSearch
      ],
      "Mix tasks": [
        Mix.Tasks.Unicode.Download
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "src", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix", "src", "bench"]
  defp elixirc_paths(_), do: ["lib", "src"]
end
