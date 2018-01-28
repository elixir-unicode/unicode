defmodule Cldr.Unicode do
  alias Cldr.Unicode.CombiningClass, as: Cc

  @data_dir Path.join(__DIR__, "/../../data") |> Path.expand
  def data_dir do
    @data_dir
  end

  @doc """
  UTS10-D33. Non-Starter: An assigned character with Canonical_Combining_Class ≠ 0.
  This definition of non-starter is based on the definition of starter. See D107 in [Unicode].

  By the definition of Canonical_Combining_Class, a non-starter must be a combining mark;
  however, not all combining marks are non-starters, because many combining marks have
  Canonical_Combining_Class = 0. A non-starter cannot be an unassigned code point: all
  unassigned code points are starters, because their Canonical_Combining_Class value
  defaults to 0.
  """
  def non_starter?([char | _rest]) do
    non_starter?(char)
  end

  def non_starter?(char) when is_integer(char) do
    Cc.combining_class(char) != 0
  end

  @doc """
  UTS10-D34. Blocking Context: The presence of a character B between two characters
  C1 and C2, where ccc(B) = 0 or ccc(B) ≥ ccc(C2). The notation ccc(B) is an
  abbreviation for "the Canonical_Combining_Class value of B".
  """
  def blocking_context?([_c1, b, c2 | _rest]) do
    (Cc.combining_class(b) == 0) or (Cc.combining_class(b) >= Cc.combining_class(c2))
  end

  @doc """
  UTS10-D35. Unblocked Non-Starter: A non-starter C2 which is not in a blocking
  context with respect to a preceding character C1 in a string.

  In the context <C1 ... B ... C2>, if there is no intervening character B
  which meets the criterion for being a blocking context, and if C2 is a
  non-starter, then it is also an unblocked non-starter.
  """
  def unblocked_non_starter?(_match) do

  end

end