# Credo configuration for Unicode.
#
# Policy decisions (July 2026), following the Localize conventions:
#
# * `Design.AliasUsage` is disabled. Unicode deliberately fully
#   qualifies many calls because module names such as
#   `Unicode.RangeSearch`, `Unicode.Property` and the property
#   modules read more clearly at the call site, and some segments
#   would shadow other modules if aliased.
#
# * `Refactor.Nesting` stays at the default maximum depth of 2:
#   multi-clause helper functions with pattern matching are preferred
#   over nested case/cond/if.
#
# * `Refactor.CyclomaticComplexity` stays at the default of 9;
#   naturally-branchy functions carry inline `credo:disable`
#   annotations with a one-line justification instead of a raised
#   global limit.
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "mix/", "test/"],
        excluded: []
      },
      checks: %{
        disabled: [
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}
