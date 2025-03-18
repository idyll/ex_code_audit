defmodule FixSpecificFile do
  @moduledoc """
  Script to check and fix sections in a specific LiveView file.

  ## Usage

  mix run fix_specific_file.exs [--preview] [--force]
  """

  def run(args) do
    # Parse arguments
    preview = Enum.member?(args, "--preview")
    force = Enum.member?(args, "--force")

    # Target file
    file_path = "test/fixtures/mock_forgot_password_live.ex"
    {:ok, content} = File.read(file_path)

    IO.puts("=== Testing LiveView fixer on: #{file_path} ===")
    IO.puts("Options: #{if preview, do: "preview", else: "fix"} #{if force, do: "force", else: ""}")

    # Sections to add (all of them in force mode)
    sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

    # In force mode, we directly apply all sections without checking for violations
    if force do
      # Apply or preview the forced fixes
      if preview do
        # Just preview the changes
        case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true, file_path: file_path, force: true) do
          {:ok, preview_text} ->
            IO.puts("\nPreview of fixes (force mode):")
            IO.puts(preview_text)

          {:error, reason} ->
            IO.puts("\nError generating preview: #{reason}")
        end
      else
        # Apply the fixes
        case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, force: true) do
          {:ok, fixed_content} ->
            case File.write(file_path, fixed_content) do
              :ok ->
                IO.puts("\n✅ Successfully fixed file (force mode): #{file_path}")
                IO.puts("  Added sections: #{Enum.join(sections_to_add, ", ")}")

              {:error, reason} ->
                IO.puts("\n❌ Error writing to file: #{reason}")
            end

          {:error, reason} ->
            IO.puts("\n❌ Error fixing file: #{reason}")
        end
      end
    else
      # Regular mode - check for violations first
      # Run analyzer to check for missing sections
      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # Check for violations
      violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

      # Filter out LiveView section violations
      liveview_violations =
        violations
        |> Enum.filter(fn violation ->
          violation.rule == :live_view_sections &&
            String.contains?(violation.message, "LiveView missing labeled sections")
        end)

      # Print summary of violations
      if Enum.empty?(liveview_violations) do
        IO.puts("\nNo LiveView section violations found in the file.")
      else
        # We have violations to fix
        IO.puts("\nFound #{length(liveview_violations)} LiveView section violations.")

        Enum.each(liveview_violations, fn violation ->
          # Extract missing sections from the violation message
          sections_to_add = find_missing_sections(violation)

          # Fix or preview
          if preview do
            # Just preview the changes
            case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true, file_path: file_path) do
              {:ok, preview_text} ->
                IO.puts("\nPreview of fixes:")
                IO.puts(preview_text)

              {:error, reason} ->
                IO.puts("\nError generating preview: #{reason}")
            end
          else
            # Apply the fixes
            case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add) do
              {:ok, fixed_content} ->
                case File.write(file_path, fixed_content) do
                  :ok ->
                    IO.puts("\n✅ Successfully fixed file: #{file_path}")
                    IO.puts("  Added sections: #{Enum.join(sections_to_add, ", ")}")

                  {:error, reason} ->
                    IO.puts("\n❌ Error writing to file: #{reason}")
                end

              {:error, reason} ->
                IO.puts("\n❌ Error fixing file: #{reason}")
            end
          end
        end)
      end
    end
  end

  # Extract missing sections from a violation message
  defp find_missing_sections(violation) do
    message = violation.message

    # Extract sections using our updated regex
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
        # Fallback
        ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]
    end
  end
end

# Get command line arguments
FixSpecificFile.run(System.argv())
