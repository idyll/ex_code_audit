defmodule ExCodeAudit.Analyzers.Schema do
  @moduledoc """
  Analyzer for schema file structure and placement.

  This analyzer checks for proper placement of schema files and for proper
  structure within schema files.
  """

  use ExCodeAudit.Rule

  alias ExCodeAudit.Violation

  @impl true
  def name, do: :schema_location

  @impl true
  def description,
    do: "Checks that schema files are in the proper location and follow conventions"

  @impl true
  def check(file_path, file_content, config) do
    # Only check Elixir files
    if is_elixir_file?(file_path) do
      # Check if the file is a schema file
      if is_schema_file?(file_content) do
        # Initialize empty violations list
        violations = []

        # Check if the schema is in the correct location
        violations =
          if in_correct_location?(file_path, config) do
            violations
          else
            [create_location_violation(file_path, config) | violations]
          end

        # Check for Repo calls if configured
        violations =
          if contains_repo_calls?(file_content) && config[:excludes] do
            [create_repo_calls_violation(file_path) | violations]
          else
            violations
          end

        violations
      else
        []
      end
    else
      []
    end
  end

  # Expose private functions for testing
  def is_elixir_file?(file_path) do
    ext = Path.extname(file_path)
    ext in [".ex", ".exs"]
  end

  def is_schema_file?(content) do
    # Look for schema module definition patterns
    schema_patterns = [
      ~r/use\s+Ecto\.Schema/,
      ~r/schema\s+"/,
      ~r/@primary_key/
    ]

    Enum.any?(schema_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  def in_correct_location?(file_path, config) do
    # Get the expected path pattern from config
    path_pattern = config[:path] || "lib/:app_name/schema/*.ex"

    # Replace :app_name with the actual app name if needed
    expected_pattern =
      if String.contains?(path_pattern, ":app_name") do
        app_name = get_app_name()
        String.replace(path_pattern, ":app_name", app_name)
      else
        path_pattern
      end

    # Convert to regex pattern
    regex_pattern =
      expected_pattern
      |> String.replace(".", "\\.")
      |> String.replace("*", ".*")
      |> Regex.compile!()

    Regex.match?(regex_pattern, file_path)
  end

  def contains_repo_calls?(content) do
    repo_patterns = [
      ~r/Repo\./,
      ~r/\.repo\./i
    ]

    Enum.any?(repo_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  def get_app_name do
    # This is a simplified approach for demonstration
    # In a real implementation, you would parse the mix.exs file
    # or get the app name from the Mix.Project

    case File.read("mix.exs") do
      {:ok, content} ->
        # Look for app: :app_name in the mix.exs file
        case Regex.run(~r/app:\s+:([a-z_]+)/, content) do
          [_, app_name] -> app_name
          _ -> "ex_code_audit"
        end

      _ ->
        "ex_code_audit"
    end
  end

  defp create_location_violation(file_path, config) do
    expected_path = config[:path] || "lib/:app_name/schema/*.ex"

    expected_path =
      if String.contains?(expected_path, ":app_name") do
        String.replace(expected_path, ":app_name", get_app_name())
      else
        expected_path
      end

    message = "Schema file found in incorrect location"
    details = "Expected location: #{expected_path}"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :error,
      rule: name()
    )
  end

  defp create_repo_calls_violation(file_path) do
    message = "Schema file contains Repo calls"
    details = "Schema files should not contain database operations"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: :warning,
      rule: :schema_content
    )
  end
end
