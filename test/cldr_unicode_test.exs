defmodule TestModule do
  require Cldr.Unicode.Guards
  import Cldr.Unicode.Guards

  def test_fun(x) when is_upper(x) do
    true
  end

  def test_fun(_x) do
    false
  end

end

defmodule Cldr.Unicode.Test do
  use ExUnit.Case

  doctest Cldr.Unicode

  test "that our guarded function returns the correct values" do
    assert TestModule.test_fun(?A) === true
    assert TestModule.test_fun(?a) === false
    assert TestModule.test_fun(?Á) === true
    assert TestModule.test_fun(?Ę) === true
  end
end
