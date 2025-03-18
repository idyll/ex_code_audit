defmodule ExCodeAudit.Fixers.UserReportedIssueTest do
  use ExUnit.Case

  alias ExCodeAudit.Fixers.LiveView
  alias ExCodeAudit.Fixers.LiveViewTestHelper

  test "user_forgot_password_live.ex reported issue" do
    # This is a simplified version of the user's file
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

    # Let's directly check what sections the analyzer would detect
    existing_sections = LiveViewTestHelper.find_sections(content)
    IO.puts("Detected sections: #{inspect(existing_sections)}")

    # This is what the mix task would do - determine needed sections
    # based on function types present in the file
    needed_sections = determine_needed_sections(content)
    IO.puts("Needed sections: #{inspect(needed_sections)}")

    # These are the sections we'd try to add
    sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

    # Call the fixer and see what happens
    result = LiveView.fix_sections(content, sections_to_add)

    case result do
      {:ok, fixed_content} ->
        IO.puts("Success! Sections were added correctly.")
        assert String.contains?(fixed_content, "# ---------- LIFECYCLE CALLBACKS ----------")
        assert String.contains?(fixed_content, "# ---------- EVENT HANDLERS ----------")
        assert String.contains?(fixed_content, "# ---------- RENDERING ----------")

      {:error, message} ->
        IO.puts("Error: #{message}")
        flunk("Failed to fix file: #{message}")
    end
  end

  # Helper to determine what sections are needed based on function types
  defp determine_needed_sections(content) do
    sections = []

    # Check for lifecycle functions
    lifecycle_patterns = [
      ~r/def\s+mount\(/,
      ~r/def\s+update\(/,
      ~r/def\s+init\(/,
      ~r/def\s+terminate\(/,
      ~r/def\s+on_mount\(/,
      ~r/def\s+handle_params\(/,
      ~r/def\s+handle_continue\(/
    ]

    sections =
      if Enum.any?(lifecycle_patterns, &Regex.match?(&1, content)) do
        ["LIFECYCLE CALLBACKS" | sections]
      else
        sections
      end

    # Check for event handler functions
    event_patterns = [
      ~r/def\s+handle_event\(/,
      ~r/def\s+handle_info\(/,
      ~r/def\s+handle_call\(/,
      ~r/def\s+handle_cast\(/
    ]

    sections =
      if Enum.any?(event_patterns, &Regex.match?(&1, content)) do
        ["EVENT HANDLERS" | sections]
      else
        sections
      end

    # Check for rendering functions
    rendering_patterns = [
      ~r/def\s+render\(/,
      ~r/def\s+component\(/,
      ~r/def\s+page_title\(/
    ]

    sections =
      if Enum.any?(rendering_patterns, &Regex.match?(&1, content)) do
        ["RENDERING" | sections]
      else
        sections
      end

    sections
  end
end
