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
  @spec fix_sections(String.t(), [String.t()], keyword() | String.t()) ::
          {:ok, String.t()} | {:error, String.t()} | {:ok, String.t()}
  def fix_sections(content, sections, opts \\ [])

  def fix_sections(content, sections, file_path) when is_binary(file_path) do
    fix_sections(content, sections, [file_path: file_path])
  end

  def fix_sections(content, sections, opts) when is_list(opts) do
    force = Keyword.get(opts, :force, false)
    preview = Keyword.get(opts, :preview, false)
    file_path = Keyword.get(opts, :file_path, nil)

    # Find existing sections in the content
    existing_sections = find_sections(content, nil)

    # Filter sections to only the ones we care about
    existing_relevant_sections = Enum.filter(existing_sections, fn section ->
      String.upcase(section) in Enum.map(sections, &String.upcase/1)
    end)

    # Check if all requested sections already exist and we're not in force mode
    if !force && Enum.count(existing_relevant_sections) == Enum.count(sections) do
      {:error, "All required sections already exist" <> if(file_path, do: " in #{file_path}", else: "")}
    else
      # Only add sections that don't exist (unless force is true)
      sections_to_add =
        if force do
          sections
        else
          sections -- existing_relevant_sections
        end

      # Apply the changes
      {modified_content, preview_text} = insert_sections(content, sections_to_add, file_path)

      if preview do
        {:ok, preview_text}
      else
        {:ok, modified_content}
      end
    end
  end

  # Find existing section labels in the content
  defp find_sections(content, sections) do
    # Match section labels in comments with any amount of leading whitespace
    # Example: # SECTION NAME or # ----- SECTION NAME -----
    # Also matches indented section headers like "  # LIFECYCLE CALLBACKS"
    section_pattern = ~r/^\s*#\s*(?:-*\s*)?([A-Z][A-Z\s]+[A-Z])(?:\s*-*)?$/m

    found_sections =
      Regex.scan(section_pattern, content)
      |> Enum.map(fn [_, section] -> String.trim(section) end)

    if sections == nil do
      found_sections
    else
      Enum.filter(found_sections, fn section -> section in sections end)
    end
  end

  # Insert sections at appropriate locations
  defp insert_sections(content, sections, file_path) do
    lines = String.split(content, "\n")

    # Collect all insertion points first, before making any changes
    insertions =
      sections
      |> Enum.map(fn section ->
        section_name = String.upcase(section)

        case find_insertion_line(section, content) do
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
  defp find_insertion_line(section, content) do
    case section do
      "LIFECYCLE CALLBACKS" ->
        # Find the first lifecycle function (mount, update, etc.)
        patterns = [
          ~r/def\s+mount\(/m,
          ~r/def\s+update\(/m,
          ~r/def\s+init\(/m,
          ~r/def\s+terminate\(/m,
          ~r/def\s+on_mount\(/m,
          ~r/def\s+handle_params\(/m,
          ~r/def\s+handle_continue\(/m
        ]

        find_first_match(content, patterns)

      "EVENT HANDLERS" ->
        # Find the first event handler function
        patterns = [
          ~r/def\s+handle_event\(/m
        ]

        find_first_match(content, patterns)

      "INFO HANDLERS" ->
        # Find the first info handler function
        patterns = [
          ~r/def\s+handle_info\(/m
        ]

        find_first_match(content, patterns)

      "RENDERING" ->
        # Find the first rendering function (render, component, etc.)
        patterns = [
          ~r/def\s+render\(/m,
          ~r/def\s+component\(/m,
          ~r/def\s+page_title\(/m
        ]

        find_first_match(content, patterns)

      _ ->
        # Default to the end of the file for unknown sections
        nil
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

  # Find the first matching line for a list of patterns
  defp find_first_match(content, patterns) do
    lines = String.split(content, "\n")

    # Try each pattern until we find a match
    Enum.reduce_while(patterns, nil, fn pattern, _acc ->
      line_with_index = Enum.with_index(lines)
                       |> Enum.find(fn {line, _idx} -> Regex.match?(pattern, line) end)

      case line_with_index do
        {line, idx} ->
          indentation = get_indentation(line)
          {:halt, {idx, indentation}}
        nil ->
          {:cont, nil}
      end
    end)
  end
end
