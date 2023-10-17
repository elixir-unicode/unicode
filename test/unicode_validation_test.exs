defmodule Unicode.Validation.UTF8.Test do
  use ExUnit.Case

  alias Unicode.Validation.UTF8.Test.Helpers, as: Helpers

  # Todo/Nice to haves:
  #  Save interesting or breaking tests.
  #  More cases

  test "single valid sequence" do
    assert Unicode.replace_invalid("é", :utf8) === "é"
  end

  test "valid sequences" do
    Enum.map(0..10_000, fn _ ->
      char = Helpers.random_valid_sequence()

      assert Unicode.replace_invalid(char, :utf8) === char
    end)
  end

  test "single truncated sequence" do
    {overlong_e, replacement} = Helpers.truncate("é")

    assert Unicode.replace_invalid(overlong_e, :utf8) === replacement
  end

  test "truncated sequences" do
    Enum.map(0..10_000, fn _ ->
      {char, rep} = Helpers.random_truncated()

      assert Unicode.replace_invalid(char, :utf8) === rep
    end)
  end

  test "single overlong sequence" do
    {overlong_e, replacement} = Helpers.overlong("é", 3)

    assert Unicode.replace_invalid(overlong_e, :utf8) === replacement
  end

  test "overlong sequences" do
    Enum.map(0..10_000, fn _ ->
      {char, rep} = Helpers.random_overlong()

      assert Unicode.replace_invalid(char, :utf8) === rep
    end)
  end

  test "clean multilingual hello world json" do
    # https://github.com/novellac/multilanguage-hello-json/tree/master
    j = File.read!("test/support/hello.json")

    assert j === Unicode.replace_invalid(j, :utf8)
  end

  test "randomly generated illegal binary stress test" do
    {invalid, correct} = Helpers.random_sequences(100_000)

    assert Unicode.replace_invalid(invalid, :utf8) === correct
  end
end
