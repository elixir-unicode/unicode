if File.exists?(Unicode.data_dir()) do
  defmodule Mix.Tasks.Unicode.Download do
    # The release channels the files currently in `data/` were generated from. Bump these when
    # `data/` is regenerated against a new Unicode release.
    #
    # The emoji default is `latest`, not a version, and deliberately so: the emoji files are
    # versioned on their own schedule and `Public/emoji/<version>/` is frequently absent. There
    # is no `Public/emoji/17.0/` directory at all — the Unicode 17.0 emoji files were only ever
    # published under `latest/`, which is why the previous version-interpolating URL 404'd and
    # `data/emoji_sequences.txt` had to be patched by hand in commit 2e7423d.
    @default_release "17.0.0"
    @default_emoji_release "latest"

    @moduledoc """
    Downloads the Unicode Character Database files required to build this library.

    Files are fetched from two independently versioned trees on `unicode.org`: the Unicode Character
    Database (UCD) and the emoji data files. Each tree has its own *release channel*, so the UCD may
    be taken from one release while the emoji files are taken from another. That separation is not
    hypothetical — the emoji files are published on their own schedule and have previously lagged a
    UCD release by weeks, which required patching `data/` by hand.

    A release channel is either a version string such as `"17.0.0"`, or the literal `"draft"` which
    selects the pre-release tree at `https://www.unicode.org/Public/draft/`. The draft tree carries
    no version segment in its path at all, which is why the two roots are resolved through functions
    rather than by interpolating a version into a URL template.

    ### Usage

        mix unicode.download
        mix unicode.download --release draft
        mix unicode.download --release 18.0.0 --emoji-release draft
        mix unicode.download --release draft --into tmp/unicode_18
        mix unicode.download --release draft --dry-run

    ### Options

    * `--release` is the release channel for the UCD tree. The default is the first of the
      `UNICODE_RELEASE` environment variable, the `:release` key of the `:unicode` application
      environment, or `#{@default_release}`.

    * `--emoji-release` is the release channel for the emoji sequence files. The default is the
      first of the `UNICODE_EMOJI_RELEASE` environment variable, the `:emoji_release` key of the
      `:unicode` application environment, the value resolved for `--release` if that is a named
      channel, or `#{@default_emoji_release}`. A version string does not propagate from `--release`
      because the emoji tree is versioned separately and often has no matching directory — there is
      no `Public/emoji/17.0/`, for example.

    * `--into` is the directory to download into. The default is `Unicode.data_dir/0`. Downloading
      into a scratch directory allows a candidate release to be diffed against the current data
      before adopting it.

    * `--dry-run` prints the resolved URL and destination of each file without downloading anything.

    ### Returns

    * `:ok` in all cases. Individual download failures are logged and do not halt the run, so that
      one unavailable file — common in a partially populated draft tree — does not discard the
      files that did download.

    """

    use Mix.Task
    require Logger

    @shortdoc "Download Unicode data files"

    @draft_release "draft"
    @latest_release "latest"

    # Channels that exist under both the UCD and emoji trees, and so propagate from `--release`
    # to `--emoji-release` when the latter is not given. A version string does not propagate.
    @named_releases [@draft_release, @latest_release]

    @unicode_unsafe_https "UNICODE_UNSAFE_HTTPS"
    @unicode_default_timeout "120000"
    @unicode_default_connection_timeout "60000"

    @switches [release: :string, emoji_release: :string, into: :string, dry_run: :boolean]

    # Each entry is `{root, source_path, destination_file}` where `root` selects which of the two
    # release channels the file hangs off. The distinction matters and is easy to lose: `emoji-data.txt`
    # lives under the *UCD* root at `ucd/emoji/`, while `emoji-sequences.txt` lives under the separate
    # emoji root. Conflating the two is what made the Unicode 17.0 emoji update a manual patch.
    @files [
      {:ucd, "UnicodeData.txt", "unicode_data.txt"},
      {:ucd, "DoNotEmit.txt", "do_not_emit.txt"},
      {:ucd, "extracted/DerivedGeneralCategory.txt", "categories.txt"},
      {:ucd, "Blocks.txt", "blocks.txt"},
      {:ucd, "Scripts.txt", "scripts.txt"},
      {:ucd, "ScriptExtensions.txt", "script_extensions.txt"},
      {:ucd, "DerivedCoreProperties.txt", "derived_properties.txt"},
      {:ucd, "extracted/DerivedCombiningClass.txt", "combining_class.txt"},
      {:ucd, "extracted/DerivedBidiClass.txt", "bidi_class.txt"},
      {:ucd, "extracted/DerivedJoiningType.txt", "joining_type.txt"},
      {:ucd, "emoji/emoji-data.txt", "emoji.txt"},
      {:ucd, "PropertyValueAliases.txt", "property_value_alias.txt"},
      {:ucd, "PropList.txt", "properties.txt"},
      {:ucd, "PropertyAliases.txt", "property_alias.txt"},
      {:ucd, "LineBreak.txt", "line_break.txt"},
      {:ucd, "auxiliary/WordBreakProperty.txt", "word_break.txt"},
      {:ucd, "auxiliary/GraphemeBreakProperty.txt", "grapheme_break.txt"},
      {:ucd, "auxiliary/SentenceBreakProperty.txt", "sentence_break.txt"},
      {:ucd, "IndicSyllabicCategory.txt", "indic_syllabic_category.txt"},
      {:ucd, "IndicPositionalCategory.txt", "indic_positional_category.txt"},
      {:ucd, "DerivedAge.txt", "derived_age.txt"},
      {:ucd, "extracted/DerivedNumericType.txt", "numeric_type.txt"},
      {:ucd, "extracted/DerivedNumericValues.txt", "numeric_values.txt"},
      {:ucd, "extracted/DerivedDecompositionType.txt", "decomposition_type.txt"},
      {:ucd, "HangulSyllableType.txt", "hangul_syllable_type.txt"},
      {:ucd, "Jamo.txt", "jamo.txt"},
      {:ucd, "VerticalOrientation.txt", "vertical_orientation.txt"},
      {:ucd, "ArabicShaping.txt", "arabic_shaping.txt"},
      {:ucd, "BidiBrackets.txt", "bidi_brackets.txt"},
      {:ucd, "DerivedNormalizationProps.txt", "normalization_props.txt"},
      {:ucd, "CaseFolding.txt", "case_folding.txt"},
      {:ucd, "SpecialCasing.txt", "special_casing.txt"},
      {:ucd, "EastAsianWidth.txt", "east_asian_width.txt"},
      {:emoji, "emoji-sequences.txt", "emoji_sequences.txt"},
      {:emoji, "emoji-zwj-sequences.txt", "emoji_zwj_sequences.txt"}
    ]

    @doc false
    def run(argv) do
      {options, _argv, _invalid} = OptionParser.parse(argv, switches: @switches)

      Application.ensure_all_started(:inets)
      Application.ensure_all_started(:ssl)

      release = release(options)
      emoji_release = emoji_release(options)
      destination_dir = destination_dir(options)
      files = required_files(release, emoji_release, destination_dir)

      if options[:dry_run] do
        Enum.each(files, fn {url, destination} -> Mix.shell().info("#{url} -> #{destination}") end)
      else
        Logger.info(
          "Downloading Unicode UCD release #{inspect(release)} and emoji release " <>
            "#{inspect(emoji_release)} into #{inspect(destination_dir)}"
        )

        File.mkdir_p!(destination_dir)
        Enum.each(files, &download_file/1)
        verify_versions(files, release)
      end

      :ok
    end

    @doc """
    Returns the list of `{url, destination}` tuples that `run/1` will download.

    ### Arguments

    * `release` is the release channel for the UCD tree. Either a version string such as `"17.0.0"`
      or the literal `"draft"`.

    * `emoji_release` is the release channel for the emoji sequence files, in the same form.

    * `destination_dir` is the directory the files will be written into.

    ### Returns

    * A list of `{url, destination_path}` tuples.

    ### Examples

        iex> [{url, _destination} | _rest] =
        ...>   Mix.Tasks.Unicode.Download.required_files("17.0.0", "17.0.0", "data")
        iex> url
        "https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt"

        iex> [{url, _destination} | _rest] =
        ...>   Mix.Tasks.Unicode.Download.required_files("draft", "draft", "data")
        iex> url
        "https://www.unicode.org/Public/draft/ucd/UnicodeData.txt"

    """
    @spec required_files(String.t(), String.t(), String.t()) :: [{String.t(), String.t()}]
    def required_files(release, emoji_release, destination_dir) do
      Enum.map(@files, fn {root, source, destination} ->
        {Path.join(root_url(root, release, emoji_release), source),
         Path.join(destination_dir, destination)}
      end)
    end

    @doc false
    def root_url(:ucd, release, _emoji_release), do: ucd_root(release)
    def root_url(:emoji, _release, emoji_release), do: emoji_root(emoji_release)

    defp ucd_root(@draft_release), do: "https://www.unicode.org/Public/draft/ucd/"
    defp ucd_root(release), do: "https://www.unicode.org/Public/#{release}/ucd/"

    defp emoji_root(@draft_release), do: "https://www.unicode.org/Public/draft/emoji/"
    defp emoji_root(@latest_release), do: "https://www.unicode.org/Public/emoji/latest/"

    defp emoji_root(release),
      do: "https://www.unicode.org/Public/emoji/#{minor_release(release)}/"

    defp minor_release(release) do
      release |> String.split(".") |> Enum.take(2) |> Enum.join(".")
    end

    defp release(options) do
      options[:release] || System.get_env("UNICODE_RELEASE") ||
        Application.get_env(:unicode, :release) || @default_release
    end

    defp emoji_release(options) do
      options[:emoji_release] || System.get_env("UNICODE_EMOJI_RELEASE") ||
        Application.get_env(:unicode, :emoji_release) || default_emoji_release(release(options))
    end

    # A named channel exists in both trees, so `--release draft` implies draft emoji too. A version
    # string does not propagate, because the emoji tree is versioned separately and often has no
    # matching directory; fall back to the pinned emoji default instead of constructing a 404.
    defp default_emoji_release(release) when release in @named_releases, do: release
    defp default_emoji_release(_version), do: @default_emoji_release

    defp destination_dir(options) do
      options[:into] || Unicode.data_dir()
    end

    defp download_file({url, destination}) do
      case get(url) do
        {:ok, body} ->
          File.write!(destination, body)
          Logger.info("Downloaded #{inspect(url)} to #{inspect(destination)}")
          {:ok, destination}

        error ->
          error
      end
    end

    # Most UCD files carry their version in the first line, as `# Blocks-18.0.0.txt`. The emoji files
    # and `UnicodeData.txt` do not, and are skipped by the check.
    @version_header ~r/^#\s+\S+-(?<version>\d+\.\d+\.\d+)\.txt/

    # A draft tree is updated piecemeal, so a download can straddle two Unicode versions. Nothing
    # downstream would notice: `Unicode.version/0` reads only `blocks.txt`. Report it here instead.
    defp verify_versions(files, release) do
      files
      |> Enum.map(fn {_url, destination} -> file_version(destination) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> report_versions(release)
    end

    defp report_versions([], _release) do
      Logger.warning("No downloaded data file carried a version header; download not verified.")
    end

    defp report_versions([version], @draft_release) do
      Logger.info("All versioned data files report Unicode #{version}")
    end

    defp report_versions([version], release) when version == release do
      Logger.info("All versioned data files report Unicode #{version}")
    end

    defp report_versions([version], release) do
      Logger.warning(
        "Requested Unicode release #{inspect(release)} but the downloaded files " <>
          "report #{inspect(version)}."
      )
    end

    defp report_versions(versions, _release) do
      Logger.warning(
        "Downloaded data files report more than one Unicode version: #{inspect(versions)}. " <>
          "The source tree is likely partially updated; re-run the download once it settles."
      )
    end

    defp file_version(path) do
      case File.stream!(path) |> Enum.take(1) do
        [line] -> extract_version(line)
        [] -> nil
      end
    rescue
      File.Error -> nil
    end

    defp extract_version(line) do
      case Regex.named_captures(@version_header, line) do
        %{"version" => version} -> version
        nil -> nil
      end
    end

    @doc """
    Securely download https content from
    a URL.

    This function uses the built-in `:httpc`
    client but enables certificate verification
    which is not enabled by `:httc` by default.

    See also https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/ssl

    ### Arguments

    * `url` is a binary URL or a `{url, list_of_headers}` tuple. If
      provided the headers are a list of `{'header_name', 'header_value'}`
      tuples. Note that the name and value are both charlists, not
      strings.

    * `options` is a keyword list of options.

    ### Options

    * `:verify_peer` is a boolean value indicating
      if peer verification should be done for this request.
      The default is `true` in which case the default
      `:ssl` options follow the [erlef guidelines](https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/ssl)
      noted above.

    * `:timeout` is the number of milliseconds available
      for the request to complete. The default is
      #{inspect(@unicode_default_timeout)}. This option may also be
      set with the `UNICODE_HTTP_TIMEOUT` environment variable.

    * `:connection_timeout` is the number of milliseconds
      available for the a connection to be estabklished to
      the remote host. The default is #{inspect(@unicode_default_connection_timeout)}.
      This option may also be set with the
      `UNICODE_HTTP_CONNECTION_TIMEOUT` environment variable.

    ### Returns

    * `{:ok, body}` if the return is successful.

    * `{:not_modified, headers}` if the request would result in
      returning the same results as one matching an etag.

    * `{:error, error}` if the download is
       unsuccessful. An error will also be logged
       in these cases.

    ### Unsafe HTTPS

    If the environment variable `UNICODE_UNSAFE_HTTPS` is
    set to anything other than `FALSE`, `false`, `nil`
    or `NIL` then no peer verification of certificates
    is performed. Setting this variable is not recommended
    but may be required is where peer verification for
    unidentified reasons. Please [open an issue](https://github.com/elixir-cldr/cldr/issues)
    if this occurs.

    ### Certificate stores

    In order to keep dependencies to a minimum,
    `get/1` attempts to locate an already installed
    certificate store. It will try to locate a
    store in the following order which is intended
    to satisfy most host systems. The certificate
    store is expected to be a path name on the
    host system.

    ```elixir
    # A certificate store configured by the
    # developer
    Application.get_env(:ex_cldr, :cacertfile)

    # Populated if hex package `CAStore` is configured
    CAStore.file_path()

    # Populated if hex package `certfi` is configured
    :certifi.cacertfile()

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
    ```

    """
    @spec get(String.t() | {String.t(), list()}, options :: Keyword.t()) ::
            {:ok, binary} | {:not_modified, any()} | {:error, any}

    def get(url, options \\ [])

    def get(url, options) when is_binary(url) and is_list(options) do
      case get_with_headers(url, options) do
        {:ok, _headers, body} -> {:ok, body}
        other -> other
      end
    end

    def get({url, headers}, options)
        when is_binary(url) and is_list(headers) and is_list(options) do
      case get_with_headers({url, headers}, options) do
        {:ok, _headers, body} -> {:ok, body}
        other -> other
      end
    end

    @doc """
    Securely download https content from
    a URL.

    This function uses the built-in `:httpc`
    client but enables certificate verification
    which is not enabled by `:httc` by default.

    See also https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/ssl

    ### Arguments

    * `url` is a binary URL or a `{url, list_of_headers}` tuple. If
      provided the headers are a list of `{'header_name', 'header_value'}`
      tuples. Note that the name and value are both charlists, not
      strings.

    * `options` is a keyword list of options.

    ### Options

    * `:verify_peer` is a boolean value indicating
      if peer verification should be done for this request.
      The default is `true` in which case the default
      `:ssl` options follow the [erlef guidelines](https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/ssl)
      noted above.

    * `:timeout` is the number of milliseconds available
      for the request to complete. The default is
      #{inspect(@unicode_default_timeout)}. This option may also be
      set with the `UNICODE_HTTP_TIMEOUT` environment variable.

    * `:connection_timeout` is the number of milliseconds
      available for the a connection to be estabklished to
      the remote host. The default is #{inspect(@unicode_default_connection_timeout)}.
      This option may also be set with the
      `UNICODE_HTTP_CONNECTION_TIMEOUT` environment variable.

    * `:https_proxy` is the URL of an https proxy to be used. The
      default is `nil`.

    ### Returns

    * `{:ok, body, headers}` if the return is successful.

    * `{:not_modified, headers}` if the request would result in
      returning the same results as one matching an etag.

    * `{:error, error}` if the download is
       unsuccessful. An error will also be logged
       in these cases.

    ### Unsafe HTTPS

    If the environment variable `UNICODE_UNSAFE_HTTPS` is
    set to anything other than `FALSE`, `false`, `nil`
    or `NIL` then no peer verification of certificates
    is performed. Setting this variable is not recommended
    but may be required is where peer verification for
    unidentified reasons. Please [open an issue](https://github.com/elixir-cldr/cldr/issues)
    if this occurs.

    ### Https Proxy

    `Cldr.Http.get/2` will look for a proxy URL in the following
    locales in the order presented:

    * `options[:https_proxy]`
    * `ex_cldr` compile-time configuration under the
      key `:ex_cldr[:https_proxy]`
    * The environment variable `HTTPS_PROXY`
    * The environment variable `https_proxy`

    ### Certificate stores

    In order to keep dependencies to a minimum,
    `get/1` attempts to locate an already installed
    certificate store. It will try to locate a
    store in the following order which is intended
    to satisfy most host systems. The certificate
    store is expected to be a path name on the
    host system.

    ```elixir
    # A certificate store configured by the
    # developer
    Application.get_env(:ex_cldr, :cacertfile)

    # Populated if hex package `CAStore` is configured
    CAStore.file_path()

    # Populated if hex package `certfi` is configured
    :certifi.cacertfile()

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
    ```

    """
    @doc since: "2.21.0"

    @spec get_with_headers(String.t() | {String.t(), list()}, options :: Keyword.t()) ::
            {:ok, list(), binary} | {:not_modified, any()} | {:error, any}

    def get_with_headers(request, options \\ [])

    def get_with_headers(url, options) when is_binary(url) do
      get_with_headers({url, []}, options)
    end

    def get_with_headers({url, headers}, options)
        when is_binary(url) and is_list(headers) and is_list(options) do
      require Logger

      hostname = String.to_charlist(URI.parse(url).host)
      url = String.to_charlist(url)
      http_options = http_opts(hostname, options)

      maybe_set_https_proxy(https_proxy(options))

      :httpc.request(:get, {url, headers}, http_options, [])
      |> handle_response(url, http_options)
    end

    defp maybe_set_https_proxy(nil) do
      :ok
    end

    defp maybe_set_https_proxy(https_proxy) do
      require Logger

      case URI.parse(https_proxy) do
        %{host: host, port: port} when is_binary(host) and is_integer(port) ->
          :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])

        _other ->
          Logger.bare_log(
            :warning,
            "https_proxy was set to an invalid value. Found #{inspect(https_proxy)}."
          )
      end
    end

    defp handle_response({:ok, {{_version, 200, _}, headers, body}}, _url, _http_options) do
      {:ok, headers, body}
    end

    defp handle_response({:ok, {{_version, 304, _}, headers, _body}}, _url, _http_options) do
      {:not_modified, headers}
    end

    defp handle_response({_, {{_version, code, message}, _headers, _body}}, url, _http_options) do
      require Logger

      Logger.bare_log(
        :error,
        "Failed to download #{inspect(url)}. " <>
          "HTTP Error: (#{code}) #{inspect(message)}"
      )

      {:error, code}
    end

    defp handle_response(
           {:error, {:failed_connect, [{_, {host, _port}}, {_, _, :timeout}]}},
           url,
           http_options
         ) do
      require Logger

      Logger.bare_log(
        :error,
        "Timeout connecting to #{inspect(host)} to download #{inspect(url)}. " <>
          "Connection time exceeded #{http_options[:connect_timeout]}ms."
      )

      {:error, :connection_timeout}
    end

    defp handle_response(
           {:error, {:failed_connect, [{_, {host, _port}}, {_, _, sys_message}]}},
           url,
           _http_options
         ) do
      require Logger

      Logger.bare_log(
        :error,
        "Failed to connect to #{inspect(host)} to download #{inspect(url)}"
      )

      {:error, sys_message}
    end

    defp handle_response({:error, {other}}, url, _http_options) do
      require Logger

      Logger.bare_log(
        :error,
        "Failed to download #{inspect(url)}. Error #{inspect(other)}"
      )

      {:error, other}
    end

    defp handle_response({:error, :timeout}, url, http_options) do
      require Logger

      Logger.bare_log(
        :error,
        "Timeout downloading from #{inspect(url)}. " <>
          "Request exceeded #{http_options[:timeout]}ms."
      )

      {:error, :timeout}
    end

    @static_certificate_locations [
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

    defp dynamic_certificate_locations do
      [
        # Configured cacertfile
        Application.get_env(:ex_cldr, :cacertfile),

        # Populated if hex package CAStore is configured. `apply/3` avoids
        # a compile-time reference to a dependency that may be absent.
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
        if(Code.ensure_loaded?(CAStore), do: apply(CAStore, :file_path, [])),

        # Populated if hex package certfi is configured. `apply/3` avoids
        # a compile-time reference to a dependency that may be absent.
        if(Code.ensure_loaded?(:certifi),
          # credo:disable-for-next-line Credo.Check.Refactor.Apply
          do: apply(:certifi, :cacertfile, []) |> List.to_string()
        )
      ]
      |> Enum.reject(&is_nil/1)
    end

    def certificate_locations do
      dynamic_certificate_locations() ++ @static_certificate_locations
    end

    @doc false
    defp certificate_store do
      certificate_locations()
      |> Enum.find(&File.exists?/1)
      |> raise_if_no_cacertfile!
      |> :erlang.binary_to_list()
    end

    defp raise_if_no_cacertfile!(nil) do
      raise RuntimeError, """
      No certificate trust store was found.
      Tried looking for: #{inspect(certificate_locations())}

      A certificate trust store is required in
      order to download locales for your configuration.

      Since ex_cldr could not detect a system
      installed certificate trust store one of the
      following actions may be taken:

      1. Install the hex package `castore`. It will
         be automatically detected after recompilation.

      2. Install the hex package `certifi`. It will
         be automatically detected after recomilation.

      3. Specify the location of a certificate trust store
         by configuring it in `config.exs` or `runtime.exs`:

         config :ex_cldr,
           cacertfile: "/path/to/cacertfile",
           ...

      """
    end

    defp raise_if_no_cacertfile!(file) do
      file
    end

    defp http_opts(hostname, options) do
      default_timeout =
        "UNICODE_HTTP_TIMEOUT"
        |> System.get_env(@unicode_default_timeout)
        |> String.to_integer()

      default_connection_timeout =
        "UNICODE_HTTP_CONNECTION_TIMEOUT"
        |> System.get_env(@unicode_default_connection_timeout)
        |> String.to_integer()

      verify_peer? = Keyword.get(options, :verify_peer, true)
      ssl_options = https_ssl_opts(hostname, verify_peer?)
      timeout = Keyword.get(options, :timeout, default_timeout)
      connection_timeout = Keyword.get(options, :connection_timeout, default_connection_timeout)

      [timeout: timeout, connect_timeout: connection_timeout, ssl: ssl_options]
    end

    @doc false
    def user_agent do
      "erlang httpc/unicode OTP version #{otp_version()}"
      |> String.to_charlist()
    end

    defp https_ssl_opts(hostname, verify_peer?) do
      if secure_ssl?() and verify_peer? do
        [
          verify: :verify_peer,
          cacertfile: certificate_store(),
          depth: 4,
          ciphers: preferred_ciphers(),
          versions: protocol_versions(),
          eccs: preferred_eccs(),
          reuse_sessions: true,
          server_name_indication: hostname,
          secure_renegotiate: true,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      else
        [
          verify: :verify_none,
          server_name_indication: hostname,
          secure_renegotiate: true,
          reuse_sessions: true,
          versions: protocol_versions(),
          ciphers: preferred_ciphers(),
          versions: protocol_versions()
        ]
      end
    end

    defp preferred_ciphers do
      preferred_ciphers =
        [
          # Cipher suites (TLS 1.3): TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          %{cipher: :aes_128_gcm, key_exchange: :any, mac: :aead, prf: :sha256},
          %{cipher: :aes_256_gcm, key_exchange: :any, mac: :aead, prf: :sha384},
          %{cipher: :chacha20_poly1305, key_exchange: :any, mac: :aead, prf: :sha256},

          # Cipher suites (TLS 1.2): ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:
          # ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:
          # ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
          %{cipher: :aes_128_gcm, key_exchange: :ecdhe_ecdsa, mac: :aead, prf: :sha256},
          %{cipher: :aes_128_gcm, key_exchange: :ecdhe_rsa, mac: :aead, prf: :sha256},
          %{cipher: :aes_256_gcm, key_exchange: :ecdh_ecdsa, mac: :aead, prf: :sha384},
          %{cipher: :aes_256_gcm, key_exchange: :ecdh_rsa, mac: :aead, prf: :sha384},
          %{cipher: :chacha20_poly1305, key_exchange: :ecdhe_ecdsa, mac: :aead, prf: :sha256},
          %{cipher: :chacha20_poly1305, key_exchange: :ecdhe_rsa, mac: :aead, prf: :sha256},
          %{cipher: :aes_128_gcm, key_exchange: :dhe_rsa, mac: :aead, prf: :sha256},
          %{cipher: :aes_256_gcm, key_exchange: :dhe_rsa, mac: :aead, prf: :sha384}
        ]

      :ssl.filter_cipher_suites(preferred_ciphers, [])
    end

    defp protocol_versions do
      if otp_version() < 25 do
        [:"tlsv1.2"]
      else
        [:"tlsv1.2", :"tlsv1.3"]
      end
    end

    defp preferred_eccs do
      # TLS curves: X25519, prime256v1, secp384r1
      preferred_eccs = [:secp256r1, :secp384r1]
      :ssl.eccs() -- (:ssl.eccs() -- preferred_eccs)
    end

    defp secure_ssl? do
      case String.upcase(System.get_env(@unicode_unsafe_https, "TRUE")) do
        "FALSE" -> false
        "NIL" -> false
        _other -> true
      end
    end

    defp https_proxy(options) do
      options[:https_proxy] ||
        Application.get_env(:unicode, :https_proxy) ||
        System.get_env("HTTPS_PROXY") ||
        System.get_env("https_proxy")
    end

    def otp_version do
      :erlang.system_info(:otp_release) |> List.to_integer()
    end
  end
end
