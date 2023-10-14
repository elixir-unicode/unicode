defmodule Unicode.Validation.UTF8.Test do

  alias Unicode.Validation.UTF8.Test.Helpers, as: Helpers

  # Todo:
  #   Produce randomized binaries implementations can be run against.
  #   Implement a way to save interesting or breaking tests.
  #   Also add a few sanity-check static tests.

  str = <<>>

  steps = 100

  # random valid overlong sequence | {in, out}
  Helpers.random_valid_sequence()
  |> Helpers.overlong(:rand.uniform(2))

  Helpers.random_valid_sequence(:rand.uniform(3)+1)
  |> Helpers.truncated()

  Helpers.random_valid_sequence(:rand.uniform(2)+2)
  |> Helpers.truncated(2)

  # at random points, do one of the following:
  # - truncate the sequence
  # - make them overlong
  # - insert a surrogate
  # - insert an undefined codepoint
  # ... and record the index
end
