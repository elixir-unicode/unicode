Benchee.run(%{
  "Unicode"  => fn -> Unicode.Property.uppercase?("A") end,
  "unicode regex" => fn -> Regex.match?(~r/\p{Lu}/u, "A") end,
  "regex" => fn -> Regex.match?(~r/[A-Z]/u, "A") end
  })