defmodule ExCodeAudit.Reporters.Console do
  @moduledoc """
  A reporter for outputting code audit violations to the console.

  This module formats violations in a human-readable way with color-coding,
  suitable for display in terminal output.
  """

  alias ExCodeAudit.{Violation, Runner}

  @doc """
  Reports a list of violations to the console.

  ## Parameters

  - `violations`: A list of violation structs
  - `options`: Additional options for reporting (map or keyword list)
    - `:verbose`: Whether to include detailed information

  ## Examples

      iex> violations = [%ExCodeAudit.Violation{...}, %ExCodeAudit.Violation{...}]
      iex> ExCodeAudit.Reporters.Console.report(violations)
  """
  @spec report([Violation.t()], map() | Keyword.t()) :: :ok
  def report(violations, options \\ []) do
    # Print a header
    IO.puts("\nExCodeAudit v0.1.0\n")
    IO.puts("Scanning project...\n")

    # Sort violations by level (errors first) and then by file
    violations
    |> Enum.sort_by(fn v -> {sort_level(v.level), v.file} end)
    |> Enum.each(&print_violation(&1, options))

    # Print a summary
    print_summary(violations)

    :ok
  end

  # Print a single violation
  defp print_violation(violation, options) do
    # Format the level indicator with color
    level_indicator =
      case violation.level do
        :error -> IO.ANSI.red() <> "❌ ERROR: " <> IO.ANSI.reset()
        :warning -> IO.ANSI.yellow() <> "⚠️ WARNING: " <> IO.ANSI.reset()
      end

    # Print the main violation message
    IO.puts("#{level_indicator}#{violation.message}")

    # Print the file location
    file_line =
      if violation.line do
        "#{violation.file}:#{violation.line}"
      else
        violation.file
      end

    IO.puts("   File: #{file_line}")

    # Print additional information if available and in verbose mode
    if get_option(options, :verbose, false) do
      if violation.rule do
        IO.puts("   Rule: #{violation.rule}")
      end
    end

    # Add a blank line after each violation
    IO.puts("")
  end

  # Print a summary of the violations
  defp print_summary(violations) do
    summary = Runner.violation_summary(violations)

    IO.puts("Summary:")
    IO.puts("  #{summary.errors} errors")
    IO.puts("  #{summary.warnings} warnings")
    IO.puts("  #{length(violations)} violations found in total")
    IO.puts("")

    if summary.total > 0 do
      IO.puts("Run with --details for more information on each violation.")
      IO.puts("")
    end
  end

  # Helper function to get options that works with both maps and keyword lists
  defp get_option(options, key, default) when is_list(options) do
    Keyword.get(options, key, default)
  end

  defp get_option(options, key, default) when is_map(options) do
    Map.get(options, key, default)
  end

  defp get_option(_options, _key, default) do
    default
  end

  # Helper function to sort violations by level
  defp sort_level(:error), do: 0
  defp sort_level(:warning), do: 1
end
