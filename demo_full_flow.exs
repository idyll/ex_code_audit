defmodule DemoFullFlow do
  # This script simulates the full mix task fix flow

  # Helper to find missing sections from violation message
  def find_missing_sections(violation) do
    message = violation.message

    # Extract the missing sections from the message
    # The format is "Missing sections: [\"SECTION1\", \"SECTION2\", \"SECTION3\"]"
    case Regex.run(~r/Missing sections: \[(.*?)\]/, message) do
      [_, sections_str] ->
        sections_str
        |> String.split(",")
        |> Enum.map(fn section ->
          # Remove quotes and trim
          section
          |> String.trim()
          |> String.replace(~r/^"/, "")  # Remove leading quote
          |> String.replace(~r/"$/, "")  # Remove trailing quote
        end)

      _ ->
        # Fallback to a default list of common sections
        ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]
    end
  end

  def run do
    # Create a mock environment
    file_path = "test/fixtures/mock_forgot_password_live.ex"
    {:ok, content} = File.read(file_path)

    IO.puts("=== Testing full mix task fix flow on: #{file_path} ===")

    # 1. Detect violations with the analyzer
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

    # 2. Filter LiveView violations
    liveview_violations =
      violations
      |> Enum.filter(fn violation ->
        violation.rule == :live_view_sections &&
          String.contains?(violation.message, "LiveView missing labeled sections")
      end)

    IO.puts("\nFound #{length(liveview_violations)} LiveView violations")

    # 3. Simulate the auto_fix_violations function from the mix task
    if Enum.empty?(liveview_violations) do
      IO.puts("No fixable violations found.")
    else
      # Simulate preview mode
      IO.puts("\nPreview of fixes:")

      Enum.each(liveview_violations, fn violation ->
        IO.puts("\nFile: #{violation.file}")

        # Extract the missing sections from the violation message
        sections_to_add = find_missing_sections(violation)
        IO.puts("Sections to add: #{inspect(sections_to_add)}")

        # Generate the fixed content
        case ExCodeAudit.Fixers.LiveView.fix_sections(
          content,
          sections_to_add,
          preview: true,
          file_path: file_path
        ) do
          {:ok, preview} ->
            IO.puts("\nFix Preview:")
            IO.puts(preview)

          {:error, reason} ->
            IO.puts("  Could not generate preview: #{reason}")
        end
      end)

      IO.puts("\nRun without --preview to apply these changes.")
    end
  end
end

# Run the demo
DemoFullFlow.run()
