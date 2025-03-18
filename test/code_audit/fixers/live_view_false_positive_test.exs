defmodule ExCodeAudit.Fixers.LiveViewFalsePositiveTest do
  use ExUnit.Case

  alias ExCodeAudit.Fixers.LiveView
  alias ExCodeAudit.Fixers.LiveViewTestHelper

  describe "find_sections/1" do
    test "detects accidental section-like strings in comments or content" do
      # Let's test a file with strings that might accidentally match the section pattern
      content = """
      defmodule ToucanWeb.UserForgotPasswordLive do
        use ToucanWeb, :live_view

        # Here's a comment that might accidentally include LIFECYCLE CALLBACKS as text
        # We need to make sure that RENDERING doesn't trigger a match in a comment like this

        # Even if it has dashes ---- EVENT HANDLERS ---- in a comment

        alias Toucan.Accounts

        def render(assigns) do
          ~H\"\"\"
          <div class="mx-auto max-w-sm">
            <.header class="text-center">
              Forgot your password?
              <:subtitle>We'll send a password reset link to your inbox</:subtitle>
            </.header>

            <!-- This is a comment in HTML with LIFECYCLE CALLBACKS in it -->
            <div>Some text with EVENT HANDLERS mentioned</div>
            <p>Another text with RENDERING keyword</p>
          </div>
          \"\"\"
        end

        def mount(_params, _session, socket) do
          {:ok, assign(socket, form: to_form(%{}, as: "user"))}
        end

        def handle_event("send_email", params, socket) do
          # Should not match: EVENT HANDLERS inside a multi-line
          # comment like this
          {:noreply, socket}
        end
      end
      """

      # Let's see what sections are detected
      existing_sections = LiveViewTestHelper.find_sections(content)
      IO.puts("Detected sections: #{inspect(existing_sections)}")

      # If there are false positives, this will incorrectly report sections exist
      sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

      result = LiveView.fix_sections(content, sections_to_add)

      case result do
        {:ok, fixed_content} ->
          IO.puts("Successfully fixed the file, added sections were not falsely detected")
          assert String.contains?(fixed_content, "# ---------- LIFECYCLE CALLBACKS ----------")
          assert String.contains?(fixed_content, "# ---------- EVENT HANDLERS ----------")
          assert String.contains?(fixed_content, "# ---------- RENDERING ----------")

        {:error, message} ->
          IO.puts("Error: #{message}")
          # The sections should not be detected as existing already
          assert message != "All required sections already exist. Use --force to recreate them."
      end
    end
  end
end
