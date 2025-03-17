defmodule ExCodeAudit.Reporters.Json do
  @moduledoc """
  A reporter for outputting code audit violations in JSON format.

  This module formats violations as JSON, suitable for machine consumption
  or integration with other tools.
  """

  alias ExCodeAudit.{Violation, Runner}

  @doc """
  Reports a list of violations in JSON format.

  ## Parameters

  - `violations`: A list of violation structs
  - `options`: Additional options for reporting
    - `:output`: Path to output file (optional)

  ## Examples

      iex> violations = [%ExCodeAudit.Violation{...}, %ExCodeAudit.Violation{...}]
      iex> ExCodeAudit.Reporters.Json.report(violations)
  """
  @spec report([Violation.t()], Keyword.t()) :: :ok
  def report(violations, options \\ []) do
    # Create the JSON structure
    json = %{
      summary: Runner.violation_summary(violations),
      violations: Enum.map(violations, &format_violation/1)
    }

    # Convert to JSON string
    json_string = Jason.encode!(json, pretty: true)

    # Output to file or stdout
    case Keyword.get(options, :output) do
      nil ->
        # Output to stdout
        IO.puts(json_string)

      output_path ->
        # Output to file
        File.write!(output_path, json_string)
        IO.puts("Violations written to #{output_path}")
    end

    :ok
  end

  # Format a violation for JSON output
  defp format_violation(violation) do
    %{
      message: violation.message,
      file: violation.file,
      line: violation.line,
      level: violation.level,
      rule: violation.rule
    }
  end
end
