#!/usr/bin/env elixir
# Run with: mix run test_analyzer_indentation.exs

defmodule TestAnalyzerIndentation do
  def run do
    # Test file paths
    file_without_section = "test/fixtures/test_indented_live.ex"
    file_with_section = "test/fixtures/test_indented_with_section_live.ex"

    # Read the file contents
    content_without_section = File.read!(file_without_section)
    content_with_section = File.read!(file_with_section)

    # Define configuration for the analyzer
    config = %{
      required: ["RENDERING"],
      violation_level: :warning
    }

    IO.puts("\n\n===== Testing Analyzer with File Missing Section =====")
    violations_without_section = ExCodeAudit.Analyzers.LiveView.check(
      file_without_section, content_without_section, config
    )

    if Enum.empty?(violations_without_section) do
      IO.puts("❌ Error: Analyzer didn't detect missing section")
    else
      IO.puts("✅ Success: Analyzer correctly detected missing section:")
      Enum.each(violations_without_section, fn violation ->
        IO.puts("  - #{violation.message}")
      end)
    end

    IO.puts("\n\n===== Testing Analyzer with File Containing Indented Section =====")
    violations_with_section = ExCodeAudit.Analyzers.LiveView.check(
      file_with_section, content_with_section, config
    )

    if Enum.empty?(violations_with_section) do
      IO.puts("✅ Success: Analyzer correctly recognized indented section")
    else
      IO.puts("❌ Error: Analyzer flagged indented section as missing:")
      Enum.each(violations_with_section, fn violation ->
        IO.puts("  - #{violation.message}")
      end)
    end
  end
end

TestAnalyzerIndentation.run()
