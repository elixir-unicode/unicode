defmodule ReadmeTest do
  use ExUnit.Case, async: true

  test "readme version matches mix" do
    [_, readme_version_text, _] =
      Path.join(__DIR__, "../README.md")
      |> File.read!()
      |> String.split(["<!-- BEGIN: VERSION -->", "<!-- END: VERSION -->"])

    [readme_version] = Regex.run(~r/{:unicode, \"(?<version>.*)\"}/, readme_version_text, capture: :all_names)
    {:ok, readme_version} = Version.parse_requirement(readme_version)
    [:~>, {readme_major, readme_minor, _, _, _}] = readme_version.lexed()

    %Version{major: mix_major, minor: mix_minor} =
      Mix.Project.config()[:version]
      |> Version.parse!()

    assert mix_major === readme_major
    assert mix_minor === readme_minor
  end
end
