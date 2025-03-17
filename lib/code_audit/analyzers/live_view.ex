defmodule ExCodeAudit.Analyzers.LiveView do
  @moduledoc """
  Analyzer for LiveView structure and section labeling.

  This analyzer checks for proper section labeling in LiveView modules
  to ensure they follow organizational conventions. It also checks for
  the use of external templates which should be avoided in LiveView
  components, and verifies that component structure follows best practices.
  """

  use ExCodeAudit.Rule

  alias ExCodeAudit.Violation

  @impl true
  def name, do: :live_view_sections

  @impl true
  def description,
    do:
      "Checks that LiveView modules have proper section labels and follow component structure conventions"

  @impl true
  def check(file_path, file_content, config) do
    # Skip if not a LiveView or LiveComponent file or special app_web.ex file
    if is_live_file?(file_path, file_content) && !is_special_web_file?(file_path) do
      violations = []

      # Check for required sections
      violations =
        if check_sections?(config) do
          violations ++ check_section_labels(file_path, file_content, config)
        else
          violations
        end

      # Check external templates
      violations =
        if check_external_templates?(config) do
          violations ++ check_for_external_templates(file_path, file_content, config)
        else
          violations
        end

      # Check component structure
      violations =
        if check_component_structure?(config) do
          violations ++ check_component_structure(file_path, file_content, config)
        else
          violations
        end

      violations
    else
      []
    end
  end

  # Check if the file is a LiveView or LiveComponent file
  defp is_live_file?(file_path, file_content) do
    is_elixir_file?(file_path) && is_live_view?(file_content)
  end

  # Check if we should verify section labels
  defp check_sections?(config) do
    # Get the required sections from config
    required_sections = config[:required] || []
    # Only check if there are required sections defined
    !Enum.empty?(required_sections)
  end

  # Check if we should verify external templates
  defp check_external_templates?(config) do
    config[:check_external_templates] != false
  end

  # Check if we should verify component structure
  defp check_component_structure?(config) do
    config[:check_component_structure] != false
  end

  # Check the section labels in a file
  defp check_section_labels(file_path, file_content, config) do
    # Get the required sections from config
    required_sections = config[:required] || []

    # Find all section labels in the file
    found_sections = find_sections(file_content)

    # Check for missing required sections
    missing_sections = required_sections -- found_sections

    if Enum.empty?(missing_sections) do
      []
    else
      [create_missing_sections_violation(file_path, missing_sections, config)]
    end
  end

  # Check if the file uses external templates
  defp check_for_external_templates(file_path, file_content, config) do
    if uses_external_templates?(file_content) do
      [create_external_templates_violation(file_path, config)]
    else
      []
    end
  end

  # Check if a file is an Elixir file based on extension
  defp is_elixir_file?(file_path) do
    ext = Path.extname(file_path)
    ext in [".ex", ".exs"]
  end

  # Check if a file is a LiveView module
  defp is_live_view?(content) do
    # Look for LiveView module definition patterns
    live_view_patterns = [
      ~r/use\s+Phoenix\.LiveView/,
      ~r/use\s+.*\.LiveView/,
      ~r/use\s+.*\.LiveComponent/,
      ~r/def\s+mount\(/,
      ~r/def\s+render\(/,
      ~r/def\s+handle_event\(/
    ]

    Enum.any?(live_view_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  # Check if a file is a LiveComponent
  defp is_component?(content) do
    component_patterns = [
      ~r/use\s+Phoenix\.LiveComponent/,
      ~r/use\s+.*\.LiveComponent/,
      ~r/defmodule.*Component/,
      ~r/@impl\s+true\s+def\s+update\(/
    ]

    Enum.any?(component_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  # Find all section labels in the file
  defp find_sections(content) do
    # Look for section labels in comments
    # Example: # LIFECYCLE CALLBACKS
    section_pattern = ~r/^\s*#\s*([A-Z][A-Z\s]+[A-Z])$/m

    Regex.scan(section_pattern, content)
    |> Enum.map(fn [_, section] -> String.trim(section) end)
  end

  # Create a violation for missing section labels
  defp create_missing_sections_violation(file_path, missing_sections, config) do
    sections_list = Enum.join(missing_sections, ", ")

    message = "LiveView missing labeled sections"
    details = "Missing sections: [\"#{sections_list}\"]"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :warning,
      rule: name()
    )
  end

  # Check if the LiveView uses external templates
  defp uses_external_templates?(content) do
    # Pattern for external template render calls
    # Phoenix.View.render/3, Phoenix.Template.render/2, or render_template/2
    external_template_patterns = [
      ~r/Phoenix\.View\.render/,
      ~r/Phoenix\.Template\.render/,
      ~r/render_template\(/,
      # render(assigns, "template.html")
      ~r/render\s*\([^,]*,\s*["'][^"']+\.html["']/,
      # render(assigns, :template)
      ~r/render\s*\([^,]*,\s*:[a-z_]+\)/
    ]

    Enum.any?(external_template_patterns, fn pattern ->
      Regex.match?(pattern, content)
    end)
  end

  # Create a violation for external templates usage
  defp create_external_templates_violation(file_path, config) do
    message = "LiveView uses external templates"

    details =
      "LiveView components should use embedded HEEx templates instead of external template files"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :warning,
      rule: name()
    )
  end

  # Check the component structure based on best practices
  defp check_component_structure(file_path, content, config) do
    # Only check component structure if the file is a component
    if is_component?(content) do
      violations = []

      # Check for functional component pattern (recommended)
      is_functional = Regex.match?(~r/def\s+render\s*\(\s*assigns\s*\)\s*do\s*~[HLF]/i, content)

      # Check for update callback in stateful components
      has_update_callback = Regex.match?(~r/@impl\s+true\s+def\s+update\(/, content)

      # Check for embedded HEEx template
      has_heex = Regex.match?(~r/~[HLF]"{3}|~[HLF]"/i, content)

      # Check for documented props with @moduledoc
      has_moduledoc_with_props =
        Regex.run(~r/@moduledoc\s*"""\n(.*?)"""/s, content)
        |> case do
          [_, moduledoc_content] -> String.match?(moduledoc_content, ~r/## Props/m)
          _ -> false
        end

      has_props_docs =
        Regex.match?(~r/@moduledoc.*\{:prop, /, content) ||
          Regex.match?(~r/@doc.*\{:prop, /, content) ||
          has_moduledoc_with_props

      # Add violations for missing best practices
      violations =
        if !has_heex do
          [
            create_component_violation(
              file_path,
              "Component doesn't use embedded HEEx templates",
              config
            )
            | violations
          ]
        else
          violations
        end

      # For stateful components, check for update callback
      violations =
        if !is_functional && !has_update_callback do
          [
            create_component_violation(
              file_path,
              "Stateful component missing @impl true def update callback",
              config
            )
            | violations
          ]
        else
          violations
        end

      # Check for documented props
      if !has_props_docs do
        [
          create_component_violation(
            file_path,
            "Component props are not documented with @moduledoc or @doc",
            config
          )
          | violations
        ]
      else
        violations
      end
    else
      []
    end
  end

  # Create a violation for component structure issues
  defp create_component_violation(file_path, details, config) do
    message = "LiveView component structure issue"

    Violation.new(
      "#{message}\n   #{details}",
      file_path,
      level: config[:violation_level] || :warning,
      rule: name()
    )
  end

  # Check if this is a special web file like {app_name}_web.ex that should be excluded
  defp is_special_web_file?(file_path) do
    basename = Path.basename(file_path)

    String.match?(basename, ~r/^[a-z_]+_web\.ex$/) ||
      String.match?(file_path, ~r/lib\/[a-z_]+_web\.ex$/)
  end
end
