defmodule Unicode.Block.Test do
  use ExUnit.Case, async: true

  describe "fetch/1 with canonical block names" do
    test "resolves a digit-bearing block name in any case/spacing/separator form" do
      assert {:ok, ranges} = Unicode.Block.fetch(:latin_1_supplement)
      assert Unicode.Block.fetch("Latin-1 Supplement") == {:ok, ranges}
      assert Unicode.Block.fetch("latin-1 supplement") == {:ok, ranges}
      assert Unicode.Block.fetch("Latin_1_Supplement") == {:ok, ranges}
      assert Unicode.Block.fetch("latin1supplement") == {:ok, ranges}
    end

    test "still resolves non-digit block names and short aliases" do
      assert {:ok, _} = Unicode.Block.fetch("Basic Latin")
      assert {:ok, _} = Unicode.Block.fetch("basiclatin")
    end

    test "resolves other digit-bearing or punctuated block names" do
      assert {:ok, _} = Unicode.Block.fetch("Number Forms")
      assert {:ok, _} = Unicode.Block.fetch("CJK Compatibility")
    end

    test "returns :error for an unknown block" do
      assert :error = Unicode.Block.fetch("Not A Real Block")
    end
  end
end
