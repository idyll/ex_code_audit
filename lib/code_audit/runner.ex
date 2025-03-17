defmodule ExCodeAudit.Runner do
  @moduledoc """
  The main code audit runner.

  This module orchestrates the process of finding files to analyze,
  running rules against them, and collecting violations.
  """

  alias ExCodeAudit.{Config, Rules, Violation}

  @doc """
  Runs the code audit on the given files.

  If no files are provided, it will scan all files in the project.

  ## Parameters

  - `config`: The configuration map
  - `files`: A list of file paths to analyze (optional)

  ## Returns

  A list of violations.
  """
  @spec run(Config.t(), [String.t()]) :: [Violation.t()]
  def run(config, files \\ []) do
    files =
      if files == [] do
        # Default to scanning only the lib directory when no files are specified
        scan_paths = config[:scan_paths] || ["lib/**/*.{ex,exs}"]

        # Get all files matching the scan paths
        scan_paths
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.reject(&excluded?(&1, config.excluded_paths))
      else
        files
      end

    # Get enabled rules
    enabled_rules = Rules.enabled(config)

    # Run the rules against the files
    run_rules(enabled_rules, files, config)
  end

  @doc """
  Returns whether the audit run has any errors.

  ## Parameters

  - `violations`: A list of violation structs

  ## Returns

  True if any violations are errors, false otherwise

  ## Examples

      iex> violations = [
      ...>   %ExCodeAudit.Violation{level: :warning},
      ...>   %ExCodeAudit.Violation{level: :error}
      ...> ]
      iex> ExCodeAudit.Runner.has_errors?(violations)
      true
  """
  @spec has_errors?([Violation.t()]) :: boolean()
  def has_errors?(violations) do
    Enum.any?(violations, &Violation.error?/1)
  end

  @doc """
  Returns a summary of violations.

  ## Parameters

  - `violations`: A list of violation structs

  ## Returns

  A map with counts of errors and warnings

  ## Examples

      iex> violations = [
      ...>   %ExCodeAudit.Violation{level: :warning},
      ...>   %ExCodeAudit.Violation{level: :warning},
      ...>   %ExCodeAudit.Violation{level: :error}
      ...> ]
      iex> ExCodeAudit.Runner.violation_summary(violations)
      %{errors: 1, warnings: 2, total: 3}
  """
  @spec violation_summary([Violation.t()]) :: %{
          errors: non_neg_integer(),
          warnings: non_neg_integer(),
          total: non_neg_integer()
        }
  def violation_summary(violations) do
    errors = Enum.count(violations, &Violation.error?/1)
    warnings = Enum.count(violations) - errors

    %{
      errors: errors,
      warnings: warnings,
      total: errors + warnings
    }
  end

  # Run the rules against the files and collect violations
  defp run_rules(rules, files, config) do
    rules
    |> Enum.flat_map(fn rule ->
      rule_name = rule.name()
      rule_config = Config.get_rule(config, rule_name)

      # Apply the rule to all applicable files
      files
      |> filter_files_for_rule(rule, rule_config)
      |> Enum.flat_map(fn file ->
        ExCodeAudit.Rule.check_file(rule, file, rule_config)
      end)
    end)
  end

  # Filter files to only those that should be analyzed by the given rule
  defp filter_files_for_rule(files, _rule, _rule_config) do
    # This is a simple implementation that applies all rules to all files
    # In a real implementation, you would filter based on rule-specific criteria
    files
  end

  # Check if a file path should be excluded based on excluded_paths patterns
  defp excluded?(file_path, excluded_paths) do
    # For each excluded path pattern, check if the file path matches
    Enum.any?(excluded_paths, fn excluded_pattern ->
      # Convert glob pattern to regex and check if the file path matches
      regex =
        excluded_pattern
        |> String.replace(".", "\\.")
        |> String.replace("**", ".*")
        |> String.replace("*", "[^/]*")
        |> (&"^#{&1}$").()

      Regex.match?(~r/#{regex}/, file_path)
    end)
  end
end
