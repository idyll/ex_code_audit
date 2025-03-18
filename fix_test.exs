defmodule FixTest do
  @moduledoc """
  Test script to verify the fix for the dashboard_live.ex file.

  Usage:
    mix run fix_test.exs preview  # Show preview of changes
    mix run fix_test.exs fix      # Fix the file
  """

  alias ExCodeAudit.Fixers.LiveView
  alias IO.ANSI

  @file_path "test/fixtures/dashboard_live.ex"
  @fixed_file_path "test/fixtures/dashboard_live_fixed.ex"
  @sections_to_add ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

  def run(args \\ []) do
    IO.puts(ANSI.green() <> "LiveView Section Fixer - Fix Test" <> ANSI.reset())
    IO.puts("File: #{@file_path}\n")

    mode = parse_mode(args)

    case File.read(@file_path) do
      {:ok, content} ->
        case mode do
          :preview ->
            preview_fixes(content)
          :fix ->
            apply_fixes(content)
          :show ->
            # Just show the file content
            IO.puts("Original file content:\n")
            IO.puts(content)
        end

      {:error, reason} ->
        IO.puts(ANSI.red() <> "Error reading file: #{reason}" <> ANSI.reset())
    end
  end

  defp parse_mode(args) do
    case List.first(args) do
      "fix" -> :fix
      "show" -> :show
      _ -> :preview
    end
  end

  defp preview_fixes(content) do
    IO.puts("Preview changes:\n")

    case LiveView.fix_sections(content, @sections_to_add, preview: true, file_path: @file_path) do
      {:ok, preview} ->
        # Format the preview with colors
        formatted_preview = format_preview(preview)
        IO.puts(formatted_preview)

        IO.puts("\nTo apply these changes, run:")
        IO.puts(ANSI.cyan() <> "mix run fix_test.exs fix" <> ANSI.reset())

      {:error, reason} ->
        IO.puts(ANSI.red() <> "Error generating preview: #{reason}" <> ANSI.reset())
    end
  end

  defp apply_fixes(content) do
    IO.puts("Fixing LiveView section issues:")

    case LiveView.fix_sections(content, @sections_to_add, file_path: @file_path) do
      {:ok, fixed_content} ->
        # Save to file
        case File.write(@fixed_file_path, fixed_content) do
          :ok ->
            sections_str = Enum.join(@sections_to_add, ", ")
            IO.puts(ANSI.green() <> "  ✓ #{@fixed_file_path} (added: #{sections_str})" <> ANSI.reset())
            IO.puts("\n" <> ANSI.green() <> "✓ Fixed 1 file(s)." <> ANSI.reset())
            IO.puts("\nThe fixed file has been saved to: #{@fixed_file_path}")

            # Display the fixed content
            IO.puts("\nFixed file content:\n")
            IO.puts(fixed_content)

          {:error, reason} ->
            IO.puts(ANSI.red() <> "  ✗ Failed to write to #{@fixed_file_path}: #{reason}" <> ANSI.reset())
        end

      {:error, reason} ->
        IO.puts(ANSI.red() <> "  ✗ Failed to fix file: #{reason}" <> ANSI.reset())
    end
  end

  defp format_preview(preview) do
    preview
    |> String.split("\n")
    |> Enum.map(fn line ->
      cond do
        String.starts_with?(line, "+") ->
          "#{ANSI.green()}#{line}#{ANSI.reset()}"
        String.starts_with?(line, "##") ->
          "#{ANSI.cyan()}#{line}#{ANSI.reset()}"
        String.starts_with?(line, "Preview changes:") ->
          "#{ANSI.bright()}#{line}#{ANSI.reset()}"
        true ->
          line
      end
    end)
    |> Enum.join("\n")
  end
end

# Run the script
FixTest.run(System.argv())
