defmodule ExCodeAudit.Analyzers.LiveViewTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.LiveView

  describe "name/0" do
    test "returns the correct rule name" do
      assert LiveView.name() == :live_view_sections
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert LiveView.description() != ""
      assert is_binary(LiveView.description())
    end
  end

  describe "check/3" do
    test "identifies LiveView files with missing sections" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # RENDERING

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end

        def handle_event("save", %{"user" => user_params}, socket) do
          {:noreply, socket}
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # Test with a LiveView file missing the EVENT HANDLERS section
      # for a function that actually exists
      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :live_view_sections
      assert violation.file == "lib/my_app_web/live/user_live/index.ex"
      assert String.contains?(violation.message, "LiveView missing labeled sections")
      assert String.contains?(violation.message, "EVENT HANDLERS")
    end

    test "recognizes LiveView file containing ToucanWeb pattern" do
      # This test mimics the user's real file structure
      content = """
      defmodule ToucanWeb.UserForgotPasswordLive do
        use ToucanWeb, :live_view

        alias Toucan.Accounts

        def render(assigns) do
          ~H\"\"\"
          <div class="mx-auto max-w-sm">
            <.header class="text-center">
              Forgot your password?
              <:subtitle>We'll send a password reset link to your inbox</:subtitle>
            </.header>
          </div>
          \"\"\"
        end

        def mount(_params, _session, socket) do
          {:ok, assign(socket, form: to_form(%{}, as: "user"))}
        end

        def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
          if user = Accounts.get_user_by_email(email) do
            Accounts.deliver_user_reset_password_instructions(
              user,
              fn token -> url(~p"/users/reset_password/\#{token}") end
            )
          end

          info =
            "If your email is in our system, you will receive instructions to reset your password shortly."

          {:noreply, socket |> put_flash(:info, info) |> redirect(to: ~p"/")}
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      violations = LiveView.check("lib/toucan_web/live/user_forgot_password_live.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :live_view_sections
      assert violation.file == "lib/toucan_web/live/user_forgot_password_live.ex"
      assert String.contains?(violation.message, "LiveView missing labeled sections")
      assert String.contains?(violation.message, "LIFECYCLE CALLBACKS")
      assert String.contains?(violation.message, "EVENT HANDLERS")
      assert String.contains?(violation.message, "RENDERING")
    end

    test "ignores non-LiveView files" do
      content = """
      defmodule MyApp.User do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string

          timestamps()
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # Test with a non-LiveView file
      assert LiveView.check("lib/my_app/schema/user.ex", content, config) == []
    end

    test "accepts LiveView files with all required sections for existing functions" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # EVENT HANDLERS

        def handle_event("save", %{"user" => user_params}, socket) do
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

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # Test with a LiveView file containing all required sections for existing functions
      assert LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config) == []
    end

    test "doesn't require sections for functions that don't exist" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # RENDERING

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # This LiveView has no event handler functions, so
      # the EVENT HANDLERS section should not be required
      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)
      assert violations == []
    end

    test "requires sections based on function presence" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def handle_params(_params, _uri, socket) do
          {:noreply, socket}
        end

        def handle_event("save", %{"user" => user_params}, socket) do
          {:noreply, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <div>Hello World</div>
          \"\"\"
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        violation_level: :warning
      }

      # This LiveView has all types of functions but no sections
      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert String.contains?(violation.message, "LiveView missing labeled sections")
      # Should identify all three missing sections since functions of all types exist
      assert String.contains?(violation.message, "LIFECYCLE CALLBACKS")
      assert String.contains?(violation.message, "EVENT HANDLERS")
      assert String.contains?(violation.message, "RENDERING")
    end

    test "detects external templates in LiveView files" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        # EVENT HANDLERS

        def handle_event("save", %{"user" => user_params}, socket) do
          {:noreply, socket}
        end

        # RENDERING

        def render(assigns) do
          Phoenix.View.render(MyAppWeb.UserView, "index.html", assigns)
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_external_templates: true,
        violation_level: :warning
      }

      # Test with a LiveView file using external templates
      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :live_view_sections
      assert violation.file == "lib/my_app_web/live/user_live/index.ex"
      assert String.contains?(violation.message, "LiveView uses external templates")
    end

    test "detects render with template string as external template" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS
        # EVENT HANDLERS
        # RENDERING

        def render(assigns) do
          render(assigns, "index.html")
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_external_templates: true,
        violation_level: :warning
      }

      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)

      assert length(violations) == 1
      assert String.contains?(hd(violations).message, "LiveView uses external templates")
    end

    test "allows disabling external templates check" do
      content = """
      defmodule MyAppWeb.UserLive.Index do
        use MyAppWeb, :live_view

        # LIFECYCLE CALLBACKS
        # EVENT HANDLERS
        # RENDERING

        def render(assigns) do
          Phoenix.View.render(MyAppWeb.UserView, "index.html", assigns)
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_external_templates: false,
        violation_level: :warning
      }

      violations = LiveView.check("lib/my_app_web/live/user_live/index.ex", content, config)

      assert violations == []
    end

    test "detects component structure issues" do
      content = """
      defmodule MyAppWeb.Components.Button do
        use Phoenix.LiveComponent

        # LIFECYCLE CALLBACKS
        # EVENT HANDLERS
        # RENDERING

        def render(assigns) do
          # Does not use HEEx, does not document props
          "<button class=\\"button\\">Button</button>"
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_component_structure: true,
        violation_level: :warning
      }

      violations = LiveView.check("lib/my_app_web/components/button.ex", content, config)

      assert length(violations) >= 1
      violation_messages = Enum.map(violations, & &1.message)

      assert Enum.any?(violation_messages, fn msg ->
               String.contains?(msg, "Component doesn't use embedded HEEx templates")
             end) ||
               Enum.any?(violation_messages, fn msg ->
                 String.contains?(msg, "Component props are not documented")
               end) ||
               Enum.any?(violation_messages, fn msg ->
                 String.contains?(
                   msg,
                   "Stateful component missing @impl true def update callback"
                 )
               end)
    end

    test "accepts well-structured functional components" do
      content = """
      defmodule MyAppWeb.Components.Button do
        @moduledoc \"\"\"
        Button component

        ## Props

          * `type` - The button type (default: "button")
          * `class` - Additional CSS classes
          * `label` - The button label

        ## Examples

            <.button type="submit" label="Save" />
        \"\"\"
        use Phoenix.Component

        # RENDERING

        def button(assigns) do
          ~H\"\"\"
          <button type={@type} class={["button", @class]}>
            <%= @label %>
          </button>
          \"\"\"
        end
      end
      """

      config = %{
        required: ["RENDERING"],
        check_component_structure: true,
        violation_level: :warning
      }

      violations = LiveView.check("lib/my_app_web/components/button.ex", content, config)

      assert violations == []
    end

    test "accepts well-structured stateful components" do
      content = """
      defmodule MyAppWeb.Components.Modal do
        @moduledoc \"\"\"
        Modal component

        ## Props

          * `id` - Required unique ID for the modal
          * `title` - The modal title
          * `show` - Whether the modal is visible
        \"\"\"
        use Phoenix.LiveComponent

        # LIFECYCLE CALLBACKS

        @impl true
        def update(assigns, socket) do
          {:ok, assign(socket, assigns)}
        end

        # EVENT HANDLERS

        @impl true
        def handle_event("close", _, socket) do
          {:noreply, socket}
        end

        # RENDERING

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div id={@id} class="modal">
            <div class="modal-content">
              <div class="modal-header">
                <h2><%= @title %></h2>
                <button phx-click="close" phx-target={@myself}>×</button>
              </div>
              <div class="modal-body">
                <%= render_slot(@inner_block) %>
              </div>
            </div>
          </div>
          \"\"\"
        end
      end
      """

      config = %{
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_component_structure: true,
        violation_level: :warning
      }

      violations = LiveView.check("lib/my_app_web/components/modal.ex", content, config)

      assert violations == []
    end
  end
end
