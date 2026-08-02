defmodule Unicode.DataConsistency.Test do
  use ExUnit.Case, async: true

  # Most UCD files carry their version in the first line, as `# Blocks-18.0.0.txt`. The emoji files
  # and `UnicodeData.txt` do not and are skipped.
  @version_header ~r/^#\s+\S+-(?<version>\d+\.\d+\.\d+)\.txt/

  defp file_versions do
    Unicode.data_dir()
    |> Path.join("*.txt")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      version =
        case File.stream!(path) |> Enum.take(1) do
          [line] -> Regex.named_captures(@version_header, line)
          [] -> nil
        end

      {Path.basename(path), version && version["version"]}
    end)
    |> Enum.reject(fn {_basename, version} -> is_nil(version) end)
  end

  test "every versioned data file reports the same Unicode version" do
    # A Unicode data update applied piecemeal leaves `data/` straddling two releases, and nothing
    # downstream would notice: `Unicode.version/0` reads only `blocks.txt`. This is the check that
    # would have caught the emoji files lagging the UCD in the Unicode 17.0 update.
    versions = file_versions()

    assert versions != []
    assert versions |> Enum.map(&elem(&1, 1)) |> Enum.uniq() |> length() == 1
  end

  test "the data file version matches Unicode.version/0" do
    {major, minor, patch} = Unicode.version()
    reported = "#{major}.#{minor}.#{patch}"

    for {basename, version} <- file_versions() do
      assert {basename, version} == {basename, reported}
    end
  end

  test "every data file the download task fetches is present" do
    # Guards against a file being added to the download manifest but never committed, which would
    # otherwise surface as a compile-time `File.Error` in whichever module first reads it.
    for {_url, destination} <-
          Mix.Tasks.Unicode.Download.required_files("18.0.0", "latest", Unicode.data_dir()) do
      assert File.exists?(destination), "missing data file: #{Path.basename(destination)}"
    end
  end
end
