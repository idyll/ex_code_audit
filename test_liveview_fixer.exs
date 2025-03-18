# This script directly tests the LiveView fixer on a sample file

# Read the sample file
file_path = "test/fixtures/mock_forgot_password_live.ex"
{:ok, content} = File.read(file_path)

IO.puts("Testing fixer on file: #{file_path}")
IO.puts("File content length: #{String.length(content)}")

# Get sections to add
sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

# Try to fix the file
case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true) do
  {:ok, preview} ->
    IO.puts("\nFix Preview:")
    IO.puts(preview)

  {:error, message} ->
    IO.puts("\nError: #{message}")
end

# Check if the LiveView analyzer would detect this file
# Check if a file is a LiveView or LiveComponent file
is_live_file? =
  is_elixir_file = Path.extname(file_path) in [".ex", ".exs"]

  # Look for LiveView module definition patterns
  live_view_patterns = [
    ~r/use\s+Phoenix\.LiveView/,
    ~r/use\s+.*\.LiveView/,
    ~r/use\s+.*\.LiveComponent/,
    ~r/def\s+mount\(/,
    ~r/def\s+render\(/,
    ~r/def\s+handle_event\(/
  ]

  is_live_view = Enum.any?(live_view_patterns, fn pattern ->
    match = Regex.match?(pattern, content)
    IO.puts("Pattern #{inspect(pattern)} match: #{match}")
    match
  end)

  is_elixir_file && is_live_view

IO.puts("\nIs LiveView file? #{is_live_file?}")

# Find existing sections in the content
section_pattern = ~r/^\s*#\s*(?:-*\s*)?([A-Z][A-Z\s]+[A-Z])(?:\s*-*)?$/m

existing_sections =
  Regex.scan(section_pattern, content)
  |> Enum.map(fn [_, section] -> String.trim(section) end)

IO.puts("\nExisting sections: #{inspect(existing_sections)}")
