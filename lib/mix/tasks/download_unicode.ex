if File.exists?(Cldr.Unicode.data_dir) do
  defmodule Mix.Tasks.Cldr.Unicode.Download do
    @moduledoc """
    Downloads the required Unicode files to support Cldr.Unicode
    """

    use Mix.Task
    require Logger

    @shortdoc "Download the Unicode data files required by Cldr.Unicode."

    @doc false
    def run(_) do
      Application.ensure_all_started :inets
      Application.ensure_all_started :ssl

      Enum.each required_files(), &download_file/1
    end

    defp required_files do
      [
        {"https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedGeneralCategory.txt",
           data_path("categories.txt")},
        {"https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt",
          data_path("blocks.txt")},
        {"https://www.unicode.org/Public/UCD/latest/ucd/Scripts.txt",
          data_path("scripts.txt")},
        {"https://www.unicode.org/Public/UCD/latest/ucd/DerivedCoreProperties.txt",
          data_path("properties.txt")}
      ]
    end

    defp download_file({url, destination}) do
      url = String.to_charlist(url)

      case :httpc.request(url) do
        {:ok, {{_version, 200, 'OK'}, _headers, body}} ->
          destination
          |> File.write!(:erlang.list_to_binary(body))

          Logger.info "Downloaded #{inspect url} to #{inspect destination}"
          {:ok, destination}
        {_, {{_version, code, message}, _headers, _body}} ->
          Logger.error "Failed to download #{inspect url}. " <>
            "HTTP Error: (#{code}) #{inspect message}"
          {:error, code}
        {:error, {:failed_connect, [{_, {host, _port}}, {_, _, sys_message}]}} ->
          Logger.error "Failed to connect to #{inspect host} to download " <>
            " #{inspect url}. Reason: #{inspect sys_message}"
          {:error, sys_message}
      end
    end

    defp data_path(filename) do
      Path.join(Cldr.Unicode.data_dir, filename)
    end
  end
end