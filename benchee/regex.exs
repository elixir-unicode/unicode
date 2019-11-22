Benchee.run(%{
  "Unicode"  => fn -> Unicode.Property.uppercase?("A") end,
  "regex" => fn -> Regex.match?(~r/\p{Lu}/u, "A") end
  })