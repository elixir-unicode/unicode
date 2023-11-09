Code.eval_file("test/support/unicode_validation_helpers.ex")
alias Unicode.Validation.UTF8.Test.Helpers, as: Helpers

{invalid_I, _valid_I} = Helpers.random_sequences(100)
{invalid_II, _valid_II} = Helpers.random_sequences(1_000)
#{invalid_III, _valid_III} = Helpers.random_sequences(100_000)
{invalid_IV, _valid_IV} = Helpers.random_sequences(1_000_000)
{invalid_V, _valid_V} = Helpers.random_sequences(10_000_000)
#{invalid_VI, valid_VI} = Helpers.random_sequences(100_000_000)

moby_dick = File.read!("benchee/support/pg2701.txt")

mb_size = fn x ->
  "(#{Float.round(byte_size(x) / (1024 ** 2), 2)} MB)"
end

Benchee.run(
  %{
    "replace_invalid" => &Unicode.Validation.UTF8.replace_invalid/1
  },
  inputs: %{
     "100 random sequences #{mb_size.(invalid_I)}" => invalid_I,
     "1k random sequences #{mb_size.(invalid_II)}" => invalid_II,
    #"100k sequences" => invalid_III,
    "1m random sequences #{mb_size.(invalid_IV)}" => invalid_IV,
    "JSON, Once Invalid (~207KB)" => File.read!("benchee/support/hll_server_list-single_error.json"),
    "10m random sequences #{mb_size.(invalid_V)}" => invalid_V,
    "Moby Dick #{mb_size.(moby_dick)}" => moby_dick,
    # "100m sequences" => invalid_VI,
  },
  time: 2,
  memory_time: 2,
  unit_scaling: :smallest
)
