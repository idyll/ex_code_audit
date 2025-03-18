defmodule TestSingleFile do
  @moduledoc """
  Script to directly test the LiveView analyzer and fixer on a single file.
  """

  def run do
    # Test file path
    file_path = "test/fixtures/dashboard_live.ex"

    # Read the content
    {:ok, content} = File.read(file_path)

    IO.puts("=== Testing LiveView analyzer on: #{file_path} ===\n")

    # Create a minimal config
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Get the analyzer and fixer modules
    analyzer = ExCodeAudit.Analyzers.LiveView
    fixer = ExCodeAudit.Fixers.LiveView

    # Run the analyzer
    violations = analyzer.check(file_path, content, config)

    IO.puts("Detected violations: #{length(violations)}")

    if Enum.empty?(violations) do
      IO.puts("\n✅ All required sections detected")

      # Try with force mode
      IO.puts("\nTesting with force mode...")
      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      case fixer.fix_sections(content, sections_to_add, force: true, preview: true) do
        {:ok, preview} ->
          IO.puts("\n✅ Force mode preview generated successfully")

        {:error, message} ->
          IO.puts("\n❌ Error in force mode: #{message}")
      end
    else
      IO.puts("\n❌ Missing section violations found")

      # Extract missing sections
      violation = List.first(violations)
      missing_sections = extract_missing_sections(violation.message)
      IO.puts("  Missing sections: #{Enum.join(missing_sections, ", ")}")

      # Get a preview of the fixes
      case fixer.fix_sections(content, missing_sections, preview: true) do
        {:ok, preview} ->
          IO.puts("\n✅ Fix preview generated successfully")

        {:error, message} ->
          IO.puts("\n❌ Error generating preview: #{message}")
      end

      # Try with a LiveView that has no sections but should require them
      test_file_without_sections()
    end
  end

  # Create a test file without sections to check if the analyzer correctly detects missing sections
  defp test_file_without_sections do
    test_file_path = "test_no_sections.ex"

    content = """
    defmodule ToucanWeb.NoSectionsLive do
      use ToucanWeb, :live_view

      alias Toucan.Accounts

      def render(assigns) do
        ~H\"\"\"
        <div>Hello world</div>
        \"\"\"
      end

      def mount(_params, _session, socket) do
        {:ok, socket}
      end

      def handle_event("save", _params, socket) do
        {:noreply, socket}
      end
    end
    """

    File.write!(test_file_path, content)

    IO.puts("\n\n=== Testing LiveView analyzer on file without sections ===\n")

    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Run the analyzer
    violations = ExCodeAudit.Analyzers.LiveView.check(test_file_path, content, config)

    if Enum.empty?(violations) do
      IO.puts("❌ Error: No violations detected in file without sections!")
    else
      IO.puts("✅ Success: Correctly detected missing sections")
      IO.puts("  Missing sections: #{length(violations)} violation(s)")
    end

    # Clean up
    File.rm(test_file_path)
  end

  # Helper to extract missing sections from violation message
  defp extract_missing_sections(message) do
    # Extract sections using regex
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
        ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]
    end
  end
end

# Run the test
TestSingleFile.run()
