defmodule Unicode.Docs.Test do
  @moduledoc """
  Asserts that the ExDoc module groups stay complete.

  ExDoc puts any module that no group names into an unnamed catch-all at the end of the sidebar, and
  says nothing about it. A module added in a later release should fail here instead.
  """

  use ExUnit.Case, async: true

  # `Unicode` is the entry point and is deliberately at the top level rather than inside a group.
  @top_level [Unicode]

  describe "groups_for_modules" do
    test "names every documented module exactly once" do
      grouped =
        Mix.Project.config()
        |> Keyword.fetch!(:docs)
        |> Keyword.fetch!(:groups_for_modules)
        |> Enum.flat_map(fn {_group, modules} -> modules end)

      assert grouped == Enum.uniq(grouped), "a module is listed in more than one group"
      assert Enum.sort(documented_modules() -- @top_level) == Enum.sort(grouped)
    end

    test "names only modules that exist and are documented" do
      grouped =
        Mix.Project.config()
        |> Keyword.fetch!(:docs)
        |> Keyword.fetch!(:groups_for_modules)
        |> Enum.flat_map(fn {_group, modules} -> modules end)

      assert grouped -- documented_modules() == []
    end
  end

  # The modules ExDoc will document: those with a moduledoc, excluding the test support modules that
  # are compiled into the application in this environment but are not part of the library.
  defp documented_modules do
    Application.load(:unicode)
    {:ok, modules} = :application.get_key(:unicode, :modules)

    for module <- modules,
        Code.ensure_loaded?(module),
        match?({:docs_v1, _, _, _, %{}, _, _}, Code.fetch_docs(module)),
        source = module.module_info(:compile)[:source],
        source != nil,
        String.contains?(to_string(source), ["/lib/", "/mix/"]),
        do: module
  end
end
