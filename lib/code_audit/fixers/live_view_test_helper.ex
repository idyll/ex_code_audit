defmodule ExCodeAudit.Fixers.LiveViewTestHelper do
  @moduledoc false

  @doc """
  Exposes the find_sections function for testing purposes
  """
  def find_sections(content) do
    # This directly calls the private function with the same implementation
    # Match section labels in comments with any amount of leading whitespace
    # Example: # SECTION NAME or # ----- SECTION NAME -----
    # Also matches indented section headers like "  # LIFECYCLE CALLBACKS"
    section_pattern = ~r/^\s*#\s*(?:-*\s*)?([A-Z][A-Z\s]+[A-Z])(?:\s*-*)?$/m

    Regex.scan(section_pattern, content)
    |> Enum.map(fn [_, section] -> String.trim(section) end)
  end
end
