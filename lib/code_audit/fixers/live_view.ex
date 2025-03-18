defmodule ExCodeAudit.Fixers.LiveView do
  @moduledoc """
  Fixes for LiveView section label issues.

  This module provides functionality to automatically fix LiveView files
  that are missing required section labels. It can insert the standard
  section labels in appropriate places within the file.

  ## Usage with Mix Task

  The fixer can be used through the mix task:

  ```bash
  # To fix all LiveView missing section issues
  mix code.audit --fix

  # To preview fixes without applying them
  mix code.audit --fix --preview

  # To force recreation of section labels even if they already exist
  mix code.audit --fix --force
  ```

  ## How It Works

  The fixer analyzes LiveView files and categorizes functions into different types:

  1. **Lifecycle Callbacks**: `mount`, `update`, `init`, etc.
  2. **Event Handlers**: `handle_event`, `handle_info`, etc.
  3. **Rendering**: `render`, `component`, etc.

  It then inserts appropriate section labels before the first function of each type.
  If a section label already exists, it won't be duplicated unless `--force` is used.
  """

  @doc """
  Fix missing section labels in a LiveView file.

  ## Parameters

  - `content` - The content of the file to fix
  - `sections` - The list of section names to add
  - `opts` - Options for the fix operation
    - `:force` - Whether to force recreation of sections even if they exist (default: false)
    - `:preview` - Whether to just generate a preview without actual fixes (default: false)
    - `:file_path` - The file path to use in the preview output (default: nil)

  ## Returns

  - `{:ok, fixed_content}` - If the fix was successful
  - `{:error, reason}` - If the fix could not be applied
  - `{:ok, preview}` - If preview option is true, returns a preview of the changes
  """
  @spec fix_sections(String.t(), [String.t()], keyword()) ::
          {:ok, String.t()} | {:error, String.t()} | {:ok, String.t(), String.t()}
  def fix_sections(content, sections, opts \\ []) do
    force = Keyword.get(opts, :force, false)
    preview = Keyword.get(opts, :preview, false)
    file_path = Keyword.get(opts, :file_path, nil)

    # Find existing sections in the content
    existing_sections = find_sections(content)

    # Check if all requested sections already exist and we're not in force mode
    if !force && Enum.all?(sections, fn section -> section in existing_sections end) do
      if preview do
        {:ok, "No changes needed - all required sections already exist."}
      else
        {:error, "All required sections already exist. Use --force to recreate them."}
      end
    else
      # Split the content into function blocks for analysis
      blocks = split_into_blocks(content)

      # Insert sections at appropriate locations
      try do
        # If force is true, we want to add all sections
        # If force is false, we only add missing sections
        sections_to_add =
          if force do
            sections
          else
            sections -- existing_sections
          end

        {fixed_content, preview_text} =
          insert_sections(content, blocks, sections_to_add, file_path)

        if preview do
          {:ok, preview_text}
        else
          {:ok, fixed_content}
        end
      rescue
        e ->
          {:error, "Failed to fix file: #{Exception.message(e)}"}
      end
    end
  end

  # Find existing section labels in the content
  defp find_sections(content) do
    # Match section labels in comments with any amount of leading whitespace
    # Example: # SECTION NAME or # ----- SECTION NAME -----
    # Also matches indented section headers like "  # LIFECYCLE CALLBACKS"
    section_pattern = ~r/^\s*#\s*(?:-*\s*)?([A-Z][A-Z\s]+[A-Z])(?:\s*-*)?$/m

    Regex.scan(section_pattern, content)
    |> Enum.map(fn [_, section] -> String.trim(section) end)
  end

  # Split the content into blocks based on function definitions
  defp split_into_blocks(content) do
    # Pattern to match function definitions
    function_pattern = ~r/^\s*(def|defp)\s+([a-zA-Z0-9_?!]+)/m
    lines = String.split(content, "\n")

    # Find all function definitions with their line numbers
    function_lines =
      Enum.with_index(lines, 1)
      |> Enum.filter(fn {line, _idx} ->
        Regex.match?(function_pattern, line)
      end)
      |> Enum.map(fn {line, idx} ->
        [_, type, name] = Regex.run(function_pattern, line)
        {idx, String.trim(name), type}
      end)

    # Group functions by type
    group_functions(function_lines)
  end

  # Group functions into categories
  defp group_functions(function_lines) do
    # Define patterns for each function type
    lifecycle_functions = ~w(mount update init terminate on_mount handle_params handle_continue)
    event_functions = ~w(handle_event handle_info handle_call handle_cast)
    rendering_functions = ~w(render component page_title _)

    # Categorize each function
    Enum.reduce(function_lines, %{lifecycle: [], events: [], rendering: []}, fn {line_num, name,
                                                                                 _type},
                                                                                acc ->
      cond do
        name in lifecycle_functions ->
          Map.update!(acc, :lifecycle, &[{line_num, name} | &1])

        name in event_functions ->
          Map.update!(acc, :events, &[{line_num, name} | &1])

        name in rendering_functions ->
          Map.update!(acc, :rendering, &[{line_num, name} | &1])

        true ->
          acc
      end
    end)
    |> Enum.map(fn {type, funcs} ->
      # Sort functions by their line position
      {type, Enum.sort_by(funcs, fn {line_num, _} -> line_num end)}
    end)
    |> Map.new()
  end

  # Insert sections at appropriate locations
  defp insert_sections(content, blocks, sections, file_path) do
    lines = String.split(content, "\n")

    # Collect all insertion points first, before making any changes
    insertions =
      sections
      |> Enum.map(fn section ->
        section_name = String.upcase(section)

        case find_insertion_line(section, blocks, lines) do
          nil -> nil
          {line_idx, indentation} ->
            # Match the indentation of the function that follows this section
            section_comment = "#{indentation}# ---------- #{section_name} ----------"
            {line_idx, section_name, section_comment}
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn {line_idx, _, _} -> line_idx end)

    # Apply insertions in reverse order (bottom-to-top) to avoid offset issues
    {result_lines, preview_parts} =
      Enum.reduce(
        Enum.reverse(insertions),
        {lines, ["Preview changes:"]},
        fn {line_idx, section_name, section_comment}, {lines_acc, preview_acc} ->
          # Insert the section comment
          {before_lines, after_lines} = Enum.split(lines_acc, line_idx)
          new_lines = before_lines ++ [section_comment] ++ after_lines

          # Create a diff-style preview - use original line numbers for preview
          line_num = line_idx + 1

          diff_preview =
            create_line_diff_preview(lines, section_comment, line_idx, line_num, file_path)

          # Add to preview (in original order)
          new_preview =
            preview_acc ++
              [
                "\n## Insert #{section_name} at line #{line_num}:",
                diff_preview
              ]

          {new_lines, new_preview}
        end
      )

    # Reverse the preview parts back to original order
    {Enum.join(result_lines, "\n"), Enum.join(preview_parts, "\n")}
  end

  # Find the appropriate line to insert a section
  defp find_insertion_line(section, blocks, lines) do
    section_type = section_to_type(section)
    functions = Map.get(blocks, section_type, [])

    case functions do
      [] ->
        # No functions of this type - no need to add section
        nil

      [{line_num, _name} | _] ->
        # Always insert directly before the function definition
        # The line_num is 1-indexed, so we need to subtract 1 to get the array index
        line_idx = line_num - 1

        # Extract indentation of the function line to match it
        function_line = Enum.at(lines, line_idx)
        indentation = get_indentation(function_line)

        {line_idx, indentation}
    end
  end

  # Extract the indentation (whitespace prefix) from a line
  defp get_indentation(line) when is_binary(line) do
    case Regex.run(~r/^(\s*)/, line) do
      [indentation] -> indentation
      [_, indentation] -> indentation
      _ -> ""
    end
  end
  defp get_indentation(_), do: ""

  # Create a diff-style preview for an insertion
  defp create_line_diff_preview(lines, section_comment, line_idx, line_num, file_path) do
    # Get context lines (3 lines before and after the insertion point)
    start_idx = max(0, line_idx - 3)
    end_idx = min(length(lines) - 1, line_idx + 3)

    # Extract the context lines
    before_lines = Enum.slice(lines, start_idx..(line_idx - 1))
    after_lines = Enum.slice(lines, line_idx..end_idx)

    # Format the diff
    before_diff =
      Enum.with_index(before_lines, start_idx + 1)
      |> Enum.map(fn {line, idx} -> "  #{idx}: #{line}" end)
      |> Enum.join("\n")

    # Format the insertion (the "+" line) - section_comment already has indentation applied
    insertion_diff = "+ #{line_num}: #{section_comment}"
    file_path_line = if file_path, do: "  #{file_path}:#{line_num}", else: nil

    # Format the lines after insertion
    after_diff =
      Enum.with_index(after_lines, line_idx + 1)
      |> Enum.map(fn {line, idx} -> "  #{idx}: #{line}" end)
      |> Enum.join("\n")

    [before_diff, insertion_diff, file_path_line, after_diff]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  # Map section name to a function type
  defp section_to_type(section) do
    case String.upcase(section) do
      "LIFECYCLE CALLBACKS" -> :lifecycle
      "EVENT HANDLERS" -> :events
      "RENDERING" -> :rendering
      _ -> :other
    end
  end
end
