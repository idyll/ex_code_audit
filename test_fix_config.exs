%{
  # Only scan our test file
  scan_paths: ["test/fixtures/mock_forgot_password_live.ex"],
  # Disable all other rules
  rules: %{
    # Only enable the LiveView rule
    live_view_sections: %{
      enabled: true,
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    },
    # Disable other rules
    file_size: %{enabled: false},
    fixture_usage: %{enabled: false},
    repo_calls: %{enabled: false},
    schema_content: %{enabled: false},
    schema_location: %{enabled: false},
    test_coverage: %{enabled: false}
  },
  # Verbose for debugging
  verbose: true
}
