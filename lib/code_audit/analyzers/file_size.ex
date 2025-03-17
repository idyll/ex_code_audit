defmodule ExCodeAudit.Analyzers.FileSize do
  @moduledoc """
  Analyzer to check file size against configured maximums.

  This analyzer counts the number of lines in each file and generates
  violations when files exceed the configured maximum or warning thresholds.
  """

  use ExCodeAudit.Rule

  alias ExCodeAudit.Violation

  @impl true
  def name, do: :file_size

  @impl true
  def description, do: "Checks file sizes against configured limits"

  @impl true
  def check(file_path, file_content, config) do
    # Skip binary files and non-text files
    with true <- is_text_file?(file_path),
         true <- is_elixir_file?(file_path) do
      # Count lines in the file
      line_count = count_lines(file_content)

      # Check against configured thresholds
      cond do
        line_count > config[:max_lines] ->
          # File exceeds max lines - create an error violation
          [
            Violation.new(
              "File exceeds maximum size limit",
              file_path,
              level: config[:violation_level],
              rule: name(),
              line: nil
            )
            |> add_details(line_count, config[:max_lines])
          ]

        line_count > config[:warning_at] ->
          # File exceeds warning threshold
          [
            Violation.new(
              "File approaches maximum size limit",
              file_path,
              level: :warning,
              rule: name(),
              line: nil
            )
            |> add_details(line_count, config[:max_lines])
          ]

        true ->
          # File is within limits
          []
      end
    else
      # Skip non-text and non-Elixir files
      false -> []
    end
  end

  # Check if a file is a text file based on extension
  defp is_text_file?(file_path) do
    # List of text file extensions to check
    text_extensions = ~w(.ex .exs .eex .heex .leex .txt .md .html .js .css)
    ext = Path.extname(file_path)

    Enum.member?(text_extensions, ext)
  end

  # Check if a file is an Elixir file based on extension
  defp is_elixir_file?(file_path) do
    ext = Path.extname(file_path)
    ext in [".ex", ".exs"]
  end

  # Count the number of lines in a file
  defp count_lines(content) do
    content
    |> String.split("\n")
    |> Enum.count()
  end

  # Add details to a violation
  defp add_details(violation, line_count, max_lines) do
    # Create a detailed message with line counts
    details = "Current size: #{line_count} lines\nRecommended max: #{max_lines} lines"

    # Append the details to the violation (this is a bit hacky but works for demo)
    Map.update(violation, :message, violation.message, fn msg ->
      "#{msg}\n   #{details}"
    end)
  end
end
