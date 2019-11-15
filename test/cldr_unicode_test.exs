defmodule TestModule do
  require Unicode.Guards
  import Unicode.Guards

  def test_fun(x) when is_upper(x) do
    true
  end

  def test_fun(_x) do
    false
  end
end

defmodule Unicode.Test do
  use ExUnit.Case

  doctest Unicode

  test "that our guarded function returns the correct values" do
    assert TestModule.test_fun(?A) === true
    assert TestModule.test_fun(?a) === false
    assert TestModule.test_fun(?Á) === true
    assert TestModule.test_fun(?Ę) === true
  end
end
