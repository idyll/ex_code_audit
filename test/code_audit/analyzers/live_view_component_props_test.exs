defmodule ExCodeAudit.Analyzers.LiveViewComponentPropsTest do
  use ExUnit.Case

  alias ExCodeAudit.Analyzers.LiveView

  test "component_props_docs rule can be excluded" do
    content = """
    defmodule MyAppWeb.ComponentWithoutPropsDocs do
      use Phoenix.LiveComponent

      def render(assigns) do
        ~H\"\"\"
        <div>Component without props docs</div>
        \"\"\"
      end
    end
    """

    # Test with default config - should find a violation
    violations = LiveView.check("lib/my_app_web/components/component.ex", content, %{
      check_component_structure: true
    })

    assert length(violations) == 1
    violation = List.first(violations)
    assert violation.message =~ "Component props are not documented"

    # Test with excluded_rules config - should not find a violation
    violations_with_exclusion = LiveView.check("lib/my_app_web/components/component.ex", content, %{
      check_component_structure: true,
      excluded_rules: ["component_props_docs"]
    })

    assert Enum.empty?(violations_with_exclusion)
  end
end
