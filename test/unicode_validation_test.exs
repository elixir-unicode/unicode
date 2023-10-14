defmodule Unicode.Validation.UTF8.Test do
  use ExUnit.Case

  alias Unicode.Validation.UTF8.Test.Helpers, as: Helpers

  # Todo:
  #   Produce randomized binaries implementations can be run against.
  #   Implement a way to save interesting or breaking tests.
  #   Also add a few sanity-check static tests.

  test "single valid sequence" do
    assert Unicode.replace_invalid("é", :utf8) === "é"
  end

  test "single truncated sequence" do
    {overlong_e, replacement} = Helpers.truncate("é")

    assert Unicode.replace_invalid(overlong_e, :utf8) === replacement
  end

  test "single overlong sequence" do
    {overlong_e, replacement} = Helpers.overlong("é", 3)

    assert Unicode.replace_invalid(overlong_e, :utf8) === replacement
  end

  test "clean multilingual hello world json" do
    # https://github.com/novellac/multilanguage-hello-json/tree/master
    j = File.read!("test/hello.json")

    assert j === Unicode.replace_invalid(j, :utf8)
  end

  test "randomly generated illegal binary" do
    # generate two binary strings, one valid and one invalid

    orig = <<>>
    final = <<>>

    File.write!("test/last_valid.bin")

    assert true === true
  end
end
