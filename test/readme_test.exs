defmodule ReadmeTest do
  use ExUnit.Case, async: true

  test "readme version matches mix" do
    [_, readme_version_text, _] =
      Path.join(__DIR__, "../README.md")
      |> File.read!()
      |> String.split(["<!-- BEGIN: VERSION -->", "<!-- END: VERSION -->"])

    [readme_version] = Regex.run(~r/{:unicode, \"~> (?<version>.*)\"}/, readme_version_text, capture: :all_names)

    mix_version = Mix.Project.config()[:version]
    assert readme_version === mix_version
  end
end
