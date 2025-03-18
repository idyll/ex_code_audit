# This script directly tests the entire LiveView analyzer and fixer pipeline

# Read the sample file
file_path = "test/fixtures/mock_forgot_password_live.ex"
{:ok, content} = File.read(file_path)

IO.puts("=== Testing LiveView analyzer and fixer on file: #{file_path} ===")
IO.puts("File content length: #{String.length(content)}")

# First run the analyzer to detect violations
config = %{
  required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
  violation_level: :warning
}

violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

if Enum.empty?(violations) do
  IO.puts("\nNo violations found by analyzer!")
else
  IO.puts("\nViolations found by analyzer: #{length(violations)}")
  Enum.each(violations, fn violation ->
    IO.puts("  - #{violation.message}")
  end)

  # Now extract the missing sections from the violation message
  violation = List.first(violations)

  # Use the exact regex from the mix task
  case Regex.run(~r/Missing sections: \[(.*?)\]/, violation.message) do
    [_, sections_str] ->
      sections_to_add =
        sections_str
        |> String.split(",")
        |> Enum.map(fn section ->
          # Remove quotes and trim
          section
          |> String.trim()
          |> String.replace(~r/^"/, "")  # Remove leading quote
          |> String.replace(~r/"$/, "")  # Remove trailing quote
        end)

      IO.puts("\nSections to add: #{inspect(sections_to_add)}")

      # Try to fix the file
      case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true) do
        {:ok, preview} ->
          IO.puts("\nFix Preview:")
          IO.puts(preview)

        {:error, message} ->
          IO.puts("\nError: #{message}")
      end

    nil ->
      IO.puts("\nCould not extract sections from violation message: #{violation.message}")
  end
end
