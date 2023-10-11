defmodule Unicode.Validation.UTF8 do
  @moduledoc false

  @dialyzer(:no_improper_lists)

  def replace_invalid(bytes, replacement \\ "�")

  def replace_invalid(<<>>, _), do: ""

  def replace_invalid(bytes, replacement) when is_binary(bytes) and is_binary(replacement) do
    find_bad_sequences(bytes)
    |> replace_bad_sequences(bytes, replacement)
  end

  defp find_bad_sequences(bytes, acc \\ [])

  defp find_bad_sequences(<<_::utf8, rest::binary>>, acc) do
    find_bad_sequences(rest, acc)
  end

  # 2/3-byte truncated
  defp find_bad_sequences(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    index = byte_size(rest)+1

    # tcp = truncated code point, must be valid for 3-bytes
    <<tcp::10>> = <<i::4, ii::6>>
    cond do
      tcp >= 32 && tcp <= 863 ->
        # valid truncated code point -> replace with 1x U+UFFD
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [{index + 1, index} | acc])
      tcp >= 896 && tcp <= 1023 ->
        # valid truncated code point -> replace with 1x U+UFFD
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [{index + 1, index} | acc])
      true ->
        # invalid truncated code point -> replace with 2x U+UFFD
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [index + 1 | [index | acc]])
    end
  end

  # 2/4-byte truncated
  defp find_bad_sequences(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    index = byte_size(rest)+1

    <<tcp::9>> = <<i::3, ii::6>>
    case tcp >= 16 && tcp <= 271 do
      true ->
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [{index+1, index} | acc])
      false ->
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [index+1 | [index | acc]])
    end
  end

  # 3/4-byte truncated
  defp find_bad_sequences(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    index = byte_size(rest)+1

    <<tcp::15>> = <<i::3, ii::6, iii::6>>
    case tcp >= 1024 && tcp <= 17407 do
      true ->
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [{index+2, index} | acc])
      false ->
        find_bad_sequences(<<n_lead::2, n_rest::6, rest::binary>>, [index+2 | [index+1 | [index | acc]]])
    end
  end

  defp find_bad_sequences(<<_::binary-size(1), rest::binary>>, acc) do
    find_bad_sequences(rest, [byte_size(rest) | acc])
  end

  defp find_bad_sequences(<<>>, acc), do: Enum.reverse(acc)

  ## 0-1 bad sequences -> short circuit

  # none
  defp replace_bad_sequences([], og, _), do: og

  # leading
  defp replace_bad_sequences([i], og, rep) when is_integer(i) and i+1 === byte_size(og) do
    dbg()
    rep <> binary_slice(og, -i..-1//1)
  end
  defp replace_bad_sequences([{i, ii}], og, rep) when i+1 === byte_size(og) do
    rep <> binary_slice(og, -ii..-1//1)
  end

  # trailing
  defp replace_bad_sequences([0], og, rep) do
    binary_slice(og, -byte_size(og)..-2//1) <> rep
  end

  defp replace_bad_sequences([{i, 0}], og, rep) do
    binary_slice(og, -byte_size(og)..-(i+2)//1) <> rep
  end

  # middle
  defp replace_bad_sequences([i], og, rep) when is_integer(i) do
    binary_slice(og, -byte_size(og)..-(i+2)) <> rep <> binary_slice(og, -i..-1//1)
  end

  defp replace_bad_sequences([{i, ii}], og, rep) do
    binary_slice(og, -byte_size(og)..-(i+2)) <> rep <> binary_slice(og, -ii..-1//1)
  end

  ## 2+ bad sequences -> recursive

  # -> start with slice from start
  defp replace_bad_sequences([i | _rest] = bytes, og, rep) when is_integer(i) and i+1 !== byte_size(og) do
    [binary_slice(og, -byte_size(og)..-(i+2)//1)]
    |> do_replace_bad_sequences(bytes, og, rep)
  end

  defp replace_bad_sequences([{i, _ii} | _rest] = bytes, og, rep) when i+1 !== byte_size(og) do
    [binary_slice(og, -byte_size(og)..-(i+2)//1)]
    |> do_replace_bad_sequences(bytes, og, rep)
  end

  # og begins with a bad sequence -> start with empty acc
  defp replace_bad_sequences(bytes, og, rep) do
    do_replace_bad_sequences([], bytes, og, rep)
  end

  # loop

  # og ends with a bad sequence -> skip slice and convert
  defp do_replace_bad_sequences(acc, [0], _og, rep) do
    [acc | rep]
    |> IO.iodata_to_binary()
  end

  defp do_replace_bad_sequences(acc, [{_ii, 0}], _og, rep) do
    [acc | rep]
    |> IO.iodata_to_binary()
  end

  # last bad sequence -> slice and convert
  defp do_replace_bad_sequences(acc, [i], og, rep) when is_integer(i) do
    [[acc | rep] | binary_slice(og, -i..-1//1)]
    |> IO.iodata_to_binary()
  end

  defp do_replace_bad_sequences(acc, [{_i, ii}], og, rep) do
    [[acc | rep] | binary_slice(og, -ii..-1//1)]
    |> IO.iodata_to_binary()
  end

  defp do_replace_bad_sequences(acc, [{_i, i} | [{ii, _} | _] = rest], og, rep) when i+1 === ii do
    [acc | rep]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [{_i, i} | [{ii, _} | _] = rest], og, rep) do
    [[acc | rep] | binary_slice(og, -i..-(ii+2)//1)]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [{_, i} | [ii | _] = rest], og, rep) when is_integer(ii) and i+1 === ii do
    [acc | rep]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [{_, i} | [ii | _] = rest], og, rep) when is_integer(ii) do
    [[acc | rep] | binary_slice(og, -i..-(ii+2)//1)]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [i | [{ii, _} | _] = rest], og, rep) when is_integer(i) and i+1 === ii do
    [acc | rep]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [i | [{ii, _} | _] = rest], og, rep) when is_integer(i) do
    [[acc | rep] | binary_slice(og, -i..-(ii+2)//1)]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [i | [ii | _] = rest], og, rep) when is_integer(i) and is_integer(ii) and i+1 === ii do
    [acc | rep]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  defp do_replace_bad_sequences(acc, [i | [ii | _] = rest], og, rep) when is_integer(i) and is_integer(ii) do
    [[acc | rep] | binary_slice(og, -i..-(ii+2)//1)]
    |> do_replace_bad_sequences(rest, og, rep)
  end
end
