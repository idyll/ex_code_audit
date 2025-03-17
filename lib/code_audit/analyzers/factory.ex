defmodule ExCodeAudit.Analyzers.Factory do
  @moduledoc """
  Analyzer for factory usage in tests.

  This analyzer checks for proper usage of factories in tests,
  verifying the existence of a Factory module and discouraging
  the use of fixtures.
  """

  use ExCodeAudit.Rule

  alias ExCodeAudit.Violation

  @impl true
  def name, do: :fixture_usage

  @impl true
  def description, do: "Checks for proper factory usage and discourages fixtures"

  @impl true
  def check(file_path, file_content, config) do
    # Only check test files
    if is_test_file?(file_path) do
      violations = []

      # Detect fixtures if they're not allowed
      violations =
        if config[:allowed] == false && uses_fixtures?(file_content) do
          [create_fixtures_violation(file_path, config) | violations]
        else
          violations
        end

      # Check if the project has a factory module (skip this check for individual files)
      if config[:check_factory_exists] && !factory_exists?() do
        [create_missing_factory_violation(file_path, config) | violations]
      else
        violations
      end
    else
      # Check for factory module (only once, when scanning non-test files)
      if !is_factory_file?(file_path) && config[:check_factory_exists] &&
           config[:factory_checked] != true && !factory_exists?() do
        # Mark as checked to avoid duplicate violations
        config_with_check = Map.put(config, :factory_checked, true)

        [create_missing_factory_violation("test/support/factory.ex", config_with_check)]
      else
        []
      end
    end
  end

  # Check if a file is a test file
  defp is_test_file?(file_path) do
    String.contains?(file_path, "/test/") || String.ends_with?(file_path, "_test.exs")
  end

  # Check if a file is the factory file
  defp is_factory_file?(file_path) do
    String.contains?(file_path, "/factory.ex")
  end

  # Check if the content uses fixtures
  defp uses_fixtures?(content) do
    fixture_patterns = [
      # Generic "fixture" word
      ~r/fixture/i,
      # Fixtures in setup blocks
      ~r/setup do[\s\S]*?fixtures/i,
      # Fixtures in setup_all blocks
      ~r/setup_all do[\s\S]*?fixtures/i,
      # Fixtures tag
      ~r/@tag fixtures/,
      # Fixture definitions
      ~r/def fixture/
    ]

    Enum.any?(fixture_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  # Check if a factory module exists in the project
  defp factory_exists? do
    factory_paths = [
      # Standard location
      "test/support/factory.ex",
      # Alternative location
      "test/factories/factory.ex",
      # Simple location
      "test/factory.ex"
    ]

    # Also check for paths that might be created in tests
    test_paths = Path.wildcard("#{System.tmp_dir()}/test/**/factory.ex")
    all_paths = factory_paths ++ test_paths

    # Also check for other factory files that might use different naming
    factory_modules = [
      # Standard name
      "Factory",
      # Alternative name (discouraged but common)
      "Factories"
    ]

    # First check for exact path matches
    path_exists = Enum.any?(all_paths, &File.exists?/1)

    # If no exact match, search for factory modules in test/**/*.ex
    module_exists =
      if !path_exists do
        # Regular project paths
        project_files = Path.wildcard("test/**/*.ex")

        # Test paths
        test_files = Path.wildcard("#{System.tmp_dir()}/test/**/*.ex")

        all_files = project_files ++ test_files

        Enum.any?(all_files, fn path ->
          {:ok, content} = File.read(path)

          Enum.any?(factory_modules, fn module ->
            Regex.match?(~r/defmodule.*#{module}/, content)
          end)
        end)
      else
        false
      end

    path_exists || module_exists
  end

  # Create a violation for fixture usage
  defp create_fixtures_violation(file_path, config) do
    message = "Test uses fixtures instead of factories"
    details = "Use factories (ExMachina) instead of fixtures for better test data management"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :warning,
      rule: name()
    )
  end

  # Create a violation for missing factory module
  defp create_missing_factory_violation(file_path, config) do
    message = "No Factory module found"
    details = "Expected a Factory module in test/support/factory.ex or similar location"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :error,
      rule: name()
    )
  end
end
