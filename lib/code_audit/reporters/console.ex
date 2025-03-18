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
    {level_text, level_color} =
      case violation.level do
        :error -> {"error", IO.ANSI.red()}
        :warning -> {"warning", IO.ANSI.yellow()}
      end

    # Extract file and line information
    file = violation.file
    line = violation.line

    # Extract the first line of the message
    {first_line, rest} =
      case String.split(violation.message, "\n", parts: 2) do
        [first, rest] -> {first, rest}
        [only] -> {only, nil}
      end

    # Print the first line with level indicator
    IO.puts("    #{level_color}#{level_text}: #{first_line}#{IO.ANSI.reset()}")

    # Add the location indicator lines if we have line information
    if line do
      # Add vertical pipe indicator
      IO.puts("    │")

      # Try to read the file and show the specific line
      case File.read(file) do
        {:ok, content} ->
          lines = String.split(content, "\n")
          if line > 0 && line <= length(lines) do
            code_line = Enum.at(lines, line - 1)

            # Trim whitespace from the beginning of the line to match compiler output format
            _indentation_size = String.length(code_line) - String.length(String.trim_leading(code_line))
            trimmed_code_line = String.trim_leading(code_line)

            # Print the line number and code
            IO.puts(" #{line} │ #{trimmed_code_line}")

            # Print the indicator under the line
            # For simplicity, we just underline a portion of the line
            indicator_position = min(String.length(trimmed_code_line), 6)
            IO.puts("    │ #{String.duplicate(" ", indicator_position)}#{level_color}^#{IO.ANSI.reset()}")
          end
        _ ->
          # If we can't read the file, skip showing the line
          :ok
      end

      # Add the source location line
      IO.puts("    │")
      IO.puts("    └─ #{file}:#{line}")
    else
      # Add the file location without line number
      IO.puts("    │")
      IO.puts("    └─ #{file}")
    end

    # If there are additional lines in the message, print them
    if rest && rest != "" do
      # Format additional lines, respecting indentation
      additional_lines = String.split(rest, "\n")

      Enum.each(additional_lines, fn line ->
        # Preserve existing formatting for additional lines
        # Most messages use "   " prefix for additional lines
        if String.starts_with?(line, "   ") do
          IO.puts(line)
        else
          IO.puts("   #{line}")
        end
      end)
    end

    # Print additional information if available and in verbose mode
    if get_option(options, :verbose, false) && violation.rule do
      IO.puts("   Rule: #{violation.rule}")
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
