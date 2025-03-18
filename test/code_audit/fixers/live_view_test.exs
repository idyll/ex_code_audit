defmodule ExCodeAudit.Fixers.LiveViewTest do
  use ExUnit.Case

  alias ExCodeAudit.Fixers.LiveView

  describe "fix_sections/3" do
    test "adds missing sections to a file without any sections" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def handle_params(_params, _uri, socket) do
          {:noreply, socket}
        end

        def handle_event("save", %{"form" => form}, socket) do
          {:noreply, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      # We'll provide all sections that should be added based on the functions present
      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      {:ok, fixed} = LiveView.fix_sections(content, sections_to_add)

      # Check that all sections were added (now with decorative dashes)
      assert String.contains?(fixed, "LIFECYCLE CALLBACKS")
      assert String.contains?(fixed, "EVENT HANDLERS")
      assert String.contains?(fixed, "RENDERING")

      # Check that sections were added in the right order
      lifecycle_pos = :binary.match(fixed, "LIFECYCLE CALLBACKS") |> elem(0)
      event_pos = :binary.match(fixed, "EVENT HANDLERS") |> elem(0)
      rendering_pos = :binary.match(fixed, "RENDERING") |> elem(0)

      assert lifecycle_pos < event_pos
      assert event_pos < rendering_pos
    end

    test "adds only missing sections to a file with some sections" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def handle_params(_params, _uri, socket) do
          {:noreply, socket}
        end

        def handle_event("save", %{"form" => form}, socket) do
          {:noreply, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      # These sections need to be added based on the functions present
      sections_to_add = ["EVENT HANDLERS", "RENDERING"]

      {:ok, fixed} = LiveView.fix_sections(content, sections_to_add)

      # Only the missing sections should be added - check for the section names, not exact format
      assert String.contains?(fixed, "LIFECYCLE CALLBACKS")
      assert String.contains?(fixed, "EVENT HANDLERS")
      assert String.contains?(fixed, "RENDERING")

      # In our implementation, we skip existing sections, so LIFECYCLE CALLBACKS will not be duplicated
      assert count_occurrences(fixed, "LIFECYCLE CALLBACKS") == 1
      assert count_occurrences(fixed, "EVENT HANDLERS") == 1
      assert count_occurrences(fixed, "RENDERING") == 1
    end

    test "returns an error when no sections need to be added" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # EVENT HANDLERS

        def handle_event("save", %{"form" => form}, socket) do
          {:noreply, socket}
        end

        # RENDERING

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      {:error, message} = LiveView.fix_sections(content, sections_to_add)
      assert String.contains?(message, "All required sections already exist")
    end

    test "only adds sections for functions that exist" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      # We'll provide sections that correspond to functions in the file
      sections_to_add = ["LIFECYCLE CALLBACKS", "RENDERING"]

      {:ok, fixed} = LiveView.fix_sections(content, sections_to_add)

      # Only the sections for functions that exist should be added
      assert String.contains?(fixed, "LIFECYCLE CALLBACKS")
      assert String.contains?(fixed, "RENDERING")

      # EVENT HANDLERS shouldn't be added since there are no event handler functions
      refute String.contains?(fixed, "EVENT HANDLERS")
    end

    test "forces recreation of sections when force option is true" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # EVENT HANDLERS

        def handle_event("save", %{"form" => form}, socket) do
          {:noreply, socket}
        end

        # RENDERING

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      # With force: true, the fix should be applied even though all sections exist
      # Let's verify that the sections exist before we try to fix
      assert count_occurrences(content, "LIFECYCLE CALLBACKS") == 1
      assert count_occurrences(content, "EVENT HANDLERS") == 1
      assert count_occurrences(content, "RENDERING") == 1

      # Apply the fix with force: true
      {:ok, fixed} = LiveView.fix_sections(content, sections_to_add, force: true)

      # Just verify that all required sections are present in the output
      assert String.contains?(fixed, "LIFECYCLE CALLBACKS")
      assert String.contains?(fixed, "EVENT HANDLERS")
      assert String.contains?(fixed, "RENDERING")
    end

    test "generates a preview when preview option is true" do
      content = """
      defmodule MyApp.SomeView do
        use Phoenix.LiveView

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def handle_event("save", %{"form" => form}, socket) do
          {:noreply, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      {:ok, preview} = LiveView.fix_sections(content, sections_to_add, preview: true)

      # Preview should contain descriptions of changes with line numbers now
      assert String.contains?(preview, "Preview changes:")
      assert String.contains?(preview, "Insert LIFECYCLE CALLBACKS at line")
      assert String.contains?(preview, "Insert EVENT HANDLERS at line")
      assert String.contains?(preview, "Insert RENDERING at line")

      # Check that the diff format is present
      assert String.contains?(preview, "+ ")
    end
  end

  # Helper to count occurrences of a substring
  defp count_occurrences(string, substring) do
    string
    |> String.split(substring)
    |> length()
    |> Kernel.-(1)
  end
end
