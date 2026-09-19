defmodule Unicode.GuidesTest do
  @moduledoc """
  Runs the examples in the guides as doctests, so a guide cannot describe behaviour the library
  does not have.
  """

  use ExUnit.Case, async: true

  doctest_file("guides/introduction.md")
end
