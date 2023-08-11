if File.exists?(Unicode.data_dir()) do
  defmodule Mix.Tasks.Unicode.Download do
    @moduledoc """
    Downloads the required Unicode files to support Unicode
    """

    use Mix.Task
    require Logger

    @shortdoc "Download Unicode data files"

    @root_url "https://www.unicode.org/Public/15.0.0/ucd/"

    @doc false
    def run(_) do
      Application.ensure_all_started(:inets)
      Application.ensure_all_started(:ssl)

      Enum.each(required_files(), &download_file/1)
    end

    defp required_files do
      [
        {Path.join(root_url(), "/UnicodeData.txt"), data_path("unicode_data.txt")},
        {Path.join(root_url(), "/extracted/DerivedGeneralCategory.txt"),
         data_path("categories.txt")},
        {Path.join(root_url(), "/Blocks.txt"), data_path("blocks.txt")},
        {Path.join(root_url(), "/Scripts.txt"), data_path("scripts.txt")},
        {Path.join(root_url(), "/DerivedCoreProperties.txt"),
         data_path("derived_properties.txt")},
        {Path.join(root_url(), "/extracted/DerivedCombiningClass.txt"),
         data_path("combining_class.txt")},
        {Path.join(root_url(), "/emoji/emoji-data.txt"), data_path("emoji.txt")},
        {Path.join(root_url(), "/PropertyValueAliases.txt"),
         data_path("property_value_alias.txt")},
        {Path.join(root_url(), "/PropList.txt"), data_path("properties.txt")},
        {Path.join(root_url(), "/PropertyAliases.txt"), data_path("property_alias.txt")},
        {Path.join(root_url(), "/LineBreak.txt"), data_path("line_break.txt")},
        {Path.join(root_url(), "/auxiliary/WordBreakProperty.txt"), data_path("word_break.txt")},
        {Path.join(root_url(), "/auxiliary/GraphemeBreakProperty.txt"),
         data_path("grapheme_break.txt")},
        {Path.join(root_url(), "/auxiliary/SentenceBreakProperty.txt"),
         data_path("sentence_break.txt")},
        {Path.join(root_url(), "/IndicSyllabicCategory.txt"),
         data_path("indic_syllabic_category.txt")},
        {Path.join(root_url(), "/CaseFolding.txt"), data_path("case_folding.txt")},
        {Path.join(root_url(), "/SpecialCasing.txt"), data_path("special_casing.txt")},
        {Path.join(root_url(), "/EastAsianWidth.txt"), data_path("east_asian_width.txt")},
        {"https://unicode.org/Public/emoji/15.0/emoji-sequences.txt",
         data_path("emoji_sequences.txt")},
        {"https://unicode.org/Public/emoji/15.0/emoji-zwj-sequences.txt",
         data_path("emoji_zwj_sequences.txt")}
      ]
    end

    def root_url do
      @root_url
    end

    defp download_file({url, destination}) do
      url = String.to_charlist(url)

      case :httpc.request(:get, {url, headers()}, https_opts(), []) do
        {:ok, {{_version, 200, ~c"OK"}, _headers, body}} ->
          destination
          |> File.write!(:erlang.list_to_binary(body))

          Logger.info("Downloaded #{inspect(url)} to #{inspect(destination)}")
          {:ok, destination}

        {_, {{_version, code, message}, _headers, _body}} ->
          Logger.error(
            "Failed to download #{inspect(url)}. " <> "HTTP Error: (#{code}) #{inspect(message)}"
          )

          {:error, code}

        {:error, {:failed_connect, [{_, {host, _port}}, {_, _, sys_message}]}} ->
          Logger.error(
            "Failed to connect to #{inspect(host)} to download " <>
              " #{inspect(url)}. Reason: #{inspect(sys_message)}"
          )

          {:error, sys_message}
      end
    end

    defp headers do
      []
    end

    @certificate_locations [
                             # Configured cacertfile
                             Application.compile_env(:unicode, :cacertfile),

                             # Populated if hex package CAStore is configured
                             if(Code.ensure_loaded?(CAStore), do: CAStore.file_path()),

                             # Populated if hex package certfi is configured
                             if(Code.ensure_loaded?(:certifi),
                               do: :certifi.cacertfile() |> List.to_string()
                             ),

                             # Debian/Ubuntu/Gentoo etc.
                             "/etc/ssl/certs/ca-certificates.crt",

                             # Fedora/RHEL 6
                             "/etc/pki/tls/certs/ca-bundle.crt",

                             # OpenSUSE
                             "/etc/ssl/ca-bundle.pem",

                             # OpenELEC
                             "/etc/pki/tls/cacert.pem",

                             # CentOS/RHEL 7
                             "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",

                             # Open SSL on MacOS
                             "/usr/local/etc/openssl/cert.pem",

                             # MacOS & Alpine Linux
                             "/etc/ssl/cert.pem"
                           ]
                           |> Enum.reject(&is_nil/1)

    def certificate_store do
      @certificate_locations
      |> Enum.find(&File.exists?/1)
      |> raise_if_no_cacertfile
      |> :erlang.binary_to_list()
    end

    defp raise_if_no_cacertfile(nil) do
      raise RuntimeError, """
      No certificate trust store was found.
      Tried looking for: #{inspect(@certificate_locations)}

      A certificate trust store is required in
      order to download locales for your configuration.

      Since no system installed certificate trust store
      could be found, one of the following actions may be
      taken:

      1. Install the hex package `castore`. It will
         be automatically detected after recompilation.

      2. Install the hex package `certifi`. It will
         be automatically detected after recomilation.

      3. Specify the location of a certificate trust store
         by configuring it in `config.exs`:

         config :unicode,
           cacertfile: "/path/to/cacertfile",
           ...

      """
    end

    defp raise_if_no_cacertfile(file) do
      file
    end

    defp https_opts do
      [
        ssl: [
          verify: :verify_peer,
          cacertfile: certificate_store(),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
    end

    defp data_path(filename) do
      Path.join(Unicode.data_dir(), filename)
    end
  end
end
