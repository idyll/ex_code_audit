#!/usr/bin/env elixir
# Run with: mix run test_indentation.exs

defmodule TestIndentation do
  def run do
    # Test file path
    file_path = "test/fixtures/test_indented_live.ex"

    # Read the file content
    file_content = File.read!(file_path)

    # Sections to add
    sections_to_add = ["RENDERING"]

    # Preview the fix
    preview_result = ExCodeAudit.Fixers.LiveView.fix_sections(file_content, sections_to_add, preview: true)

    IO.puts("\n\n===== Testing Indentation in Preview =====")

    case preview_result do
      {:ok, preview} ->
        IO.puts("Preview generated successfully.")
        IO.puts("Preview contains correct indentation: #{String.contains?(preview, "  # ---------- RENDERING ----------")}")
        IO.puts("\nPreview:\n#{preview}")

      {:error, message} ->
        IO.puts("Error: #{message}")
    end

    # Try to actually fix the file
    fix_result = ExCodeAudit.Fixers.LiveView.fix_sections(file_content, sections_to_add)

    IO.puts("\n\n===== Testing Indentation in Fixed Content =====")

    case fix_result do
      {:ok, fixed_content} ->
        IO.puts("Fix applied successfully.")
        IO.puts("Fixed content contains indented section: #{String.contains?(fixed_content, "  # ---------- RENDERING ----------")}")
        IO.puts("\nFixed content:\n#{fixed_content}")

      {:error, message} ->
        IO.puts("Error: #{message}")
    end
  end
end

TestIndentation.run()
