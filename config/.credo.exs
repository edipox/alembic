%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120}
      ],
      files: %{
        excluded: [],
        # add "test/" so tests don't get too gnarly and to remain consistent with ruby projects that run rubocop on
        # "spec/"
        included: ["lib/", "test/"]
      },
      strict: true
    }
  ]
}
