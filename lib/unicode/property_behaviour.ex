defmodule Unicode.Property.Behaviour do
  @moduledoc false

  @type codepoint_tuple :: {pos_integer, pos_integer}
  @type codepoint_list :: [codepoint_tuple, ...]
  @type property :: String.t() | atom() | pos_integer()

  @callback get(property) :: codepoint_list() | nil
  @callback fetch(property) :: {:ok, codepoint_list()} | nil
  @callback count(property) :: pos_integer
  @callback aliases() :: map()
end
