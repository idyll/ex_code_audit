defmodule AnotherTestScript do
  @moduledoc """
  Test script for demonstrating the LiveView section fixer with the another_live_view.ex file.

  Usage:
    mix run another_test_script.exs preview  # Show preview of changes
    mix run another_test_script.exs fix      # Fix the file
  """

  alias ExCodeAudit.Fixers.LiveView

  @file_path "test/fixtures/another_live_view.ex"
  @fixed_file_path "test/fixtures/another_live_view_fixed.ex"
  @sections_to_add ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

  def run(args \\ []) do
    IO.puts(IO.ANSI.green() <> "LiveView Section Fixer Demo" <> IO.ANSI.reset())
    IO.puts("File: #{@file_path}\n")

    mode = parse_mode(args)

    case File.read(@file_path) do
      {:ok, content} ->
        case mode do
          :preview ->
            preview_fixes(content)
          :fix ->
            apply_fixes(content)
        end

      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "Error reading file: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp parse_mode(args) do
    case List.first(args) do
      "fix" -> :fix
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
        IO.puts(IO.ANSI.cyan() <> "mix run another_test_script.exs fix" <> IO.ANSI.reset())

      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "Error generating preview: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp apply_fixes(content) do
    IO.puts("Fixing LiveView section issues:")

    case LiveView.fix_sections(content, @sections_to_add) do
      {:ok, fixed_content} ->
        case File.write(@fixed_file_path, fixed_content) do
          :ok ->
            sections_str = Enum.join(@sections_to_add, ", ")
            IO.puts(IO.ANSI.green() <> "  ✓ #{@fixed_file_path} (added: #{sections_str})" <> IO.ANSI.reset())
            IO.puts("\n" <> IO.ANSI.green() <> "✓ Fixed 1 file(s)." <> IO.ANSI.reset())
            IO.puts("\nThe fixed file has been saved to: #{@fixed_file_path}")

          {:error, reason} ->
            IO.puts(IO.ANSI.red() <> "  ✗ Failed to write to #{@fixed_file_path}: #{reason}" <> IO.ANSI.reset())
        end

      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "  ✗ Failed to fix file: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp format_preview(preview) do
    preview
    |> String.split("\n")
    |> Enum.map(fn line ->
      cond do
        String.starts_with?(line, "+") ->
          "#{IO.ANSI.green()}#{line}#{IO.ANSI.reset()}"
        String.starts_with?(line, "##") ->
          "#{IO.ANSI.cyan()}#{line}#{IO.ANSI.reset()}"
        String.starts_with?(line, "Preview changes:") ->
          "#{IO.ANSI.bright()}#{line}#{IO.ANSI.reset()}"
        true ->
          line
      end
    end)
    |> Enum.join("\n")
  end
end

# Run the script
AnotherTestScript.run(System.argv())
