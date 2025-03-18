defmodule DemoPreview do
  @moduledoc """
  Demo script to showcase the LiveView section fixer preview and fix functionalities.

  Usage:
  ```
  # Run in preview mode
  mix run demo_preview.exs preview

  # Run in fix mode
  mix run demo_preview.exs fix
  ```
  """

  alias ExCodeAudit.Fixers.LiveView
  alias IO.ANSI

  def run do
    # Get mode from command line args
    args = System.argv()
    mode = if length(args) > 0, do: List.first(args), else: "preview"

    file_path = "test/fixtures/demo_live_view.ex"

    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("\n#{ANSI.bright()}#{ANSI.blue()}LiveView Section Fixer Demo#{ANSI.reset()}")
        IO.puts("File: #{file_path}\n")

        # Define required sections
        sections = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

        case mode do
          "preview" ->
            # Generate the preview
            {:ok, preview} = LiveView.fix_sections(content, sections, preview: true, file_path: file_path)

            # Format and display the preview
            formatted_preview = format_preview(preview)
            IO.puts(formatted_preview)

            IO.puts("\n#{ANSI.bright()}To apply these changes, run:#{ANSI.reset()}")
            IO.puts("mix code.audit --fix")

          "fix" ->
            # Generate title
            IO.puts("#{ANSI.bright()}#{ANSI.blue()}Fixing LiveView section issues:#{ANSI.reset()}")

            # Fix the file
            case LiveView.fix_sections(content, sections, file_path: file_path) do
              {:ok, fixed_content} ->
                # Write back to a temporary file to avoid modifying the original
                temp_file = "test/fixtures/demo_live_view_fixed.ex"
                File.write!(temp_file, fixed_content)

                sections_str = Enum.join(sections, ", ")
                IO.puts("  #{ANSI.green()}✓#{ANSI.reset()} #{temp_file} #{ANSI.bright()}(added: #{sections_str})#{ANSI.reset()}")
                IO.puts("\n#{ANSI.green()}✓#{ANSI.reset()} #{ANSI.bright()}Fixed 1 file(s).#{ANSI.reset()}")

                IO.puts("\n#{ANSI.bright()}The fixed file has been saved to: #{temp_file}#{ANSI.reset()}")

              {:error, reason} ->
                IO.puts("  #{ANSI.red()}✗#{ANSI.reset()} #{file_path}: #{reason}")
            end

          _ ->
            IO.puts("#{ANSI.red()}Invalid mode: #{mode}#{ANSI.reset()}")
            IO.puts("Usage: mix run demo_preview.exs [preview|fix]")
        end

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
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

# Run the demo
DemoPreview.run()
