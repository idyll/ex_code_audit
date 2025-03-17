defmodule ExCodeAudit.Analyzers.RepoCalls do
  @moduledoc """
  Analyzer for repository call placement.

  This analyzer checks for proper placement of repository calls to ensure
  they are only used in appropriate modules.
  """

  use ExCodeAudit.Rule

  alias ExCodeAudit.Violation

  @impl true
  def name, do: :repo_calls

  @impl true
  def description, do: "Checks that repository calls are in the proper modules"

  @impl true
  def check(file_path, file_content, config) do
    # Only check Elixir files
    if is_elixir_file?(file_path) do
      # Skip files that are explicitly excluded
      unless is_excluded_path?(file_path, config) do
        # Skip files that are allowed to have repo calls
        unless is_allowed_repo_file?(file_path, config) do
          # Check for repo calls
          if contains_repo_calls?(file_content) do
            [create_repo_calls_violation(file_path, config)]
          else
            []
          end
        else
          []
        end
      else
        []
      end
    else
      []
    end
  end

  # Check if a file is an Elixir file based on extension
  defp is_elixir_file?(file_path) do
    ext = Path.extname(file_path)
    ext in [".ex", ".exs"]
  end

  # Check if a file path is explicitly excluded
  defp is_excluded_path?(file_path, config) do
    # Get the excluded patterns from config
    excluded_patterns = config[:excluded_paths] || []

    # Check if the file matches any of the excluded patterns
    Enum.any?(excluded_patterns, fn pattern ->
      matches_pattern?(file_path, pattern)
    end)
  end

  # Check if a file is allowed to have repo calls
  defp is_allowed_repo_file?(file_path, config) do
    # Get the allowed patterns from config
    allowed_patterns = config[:allowed_in] || []

    # Check if the file matches any of the allowed patterns
    Enum.any?(allowed_patterns, fn pattern ->
      matches_pattern?(file_path, pattern)
    end)
  end

  # Check if a file matches a pattern
  defp matches_pattern?(file_path, pattern) do
    # Convert pattern to regex
    regex_pattern =
      pattern
      |> String.replace(".", "\\.")
      |> String.replace("**", ".*")
      |> String.replace("*", "[^/]*")
      |> (&"^#{&1}$").()
      |> Regex.compile!()

    Regex.match?(regex_pattern, file_path)
  end

  # Check if the file contains repo calls
  defp contains_repo_calls?(content) do
    repo_patterns = [
      ~r/Repo\./,
      ~r/\.repo\./i
    ]

    Enum.any?(repo_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  # Create a violation for repo calls in the wrong place
  defp create_repo_calls_violation(file_path, config) do
    allowed_in = config[:allowed_in] || []
    allowed_list = Enum.join(allowed_in, ", ")

    message = "Repository call found in inappropriate module"
    details = "Repo calls should be in modules matching: #{allowed_list}"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :warning,
      rule: name()
    )
  end
end
