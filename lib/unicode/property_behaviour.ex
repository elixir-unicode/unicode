defmodule Unicode.Property.Behaviour do
  @moduledoc """
  Defines the behaviour required of modules that
  serve a Unicode property.

  A property server maps property values to lists
  of codepoint ranges and resolves property value
  aliases. Modules implementing this behaviour
  include `Unicode.Script`, `Unicode.Block`,
  `Unicode.GeneralCategory` and `Unicode.Property`.

  """

  @type codepoint_tuple :: {pos_integer, pos_integer}
  @type codepoint_list :: [codepoint_tuple, ...]
  @type property :: String.t() | atom() | pos_integer()

  @doc """
  Returns the list of codepoint ranges for the given
  property value or `nil` if the property value is not known.

  Property value aliases are resolved.

  """
  @callback get(property) :: codepoint_list() | nil

  @doc """
  Returns `{:ok, codepoint_list}` for the given property
  value or an error indication if the property value is not known.

  Property value aliases are resolved.

  """
  @callback fetch(property) :: {:ok, codepoint_list()} | nil

  @doc """
  Returns the number of codepoints that have the given
  property value.

  """
  @callback count(property) :: pos_integer

  @doc """
  Returns a map of aliases for the property values
  served by the implementing module.

  """
  @callback aliases() :: map()
end
