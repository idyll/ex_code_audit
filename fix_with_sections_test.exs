defmodule FixWithSectionsTest do
  @moduledoc """
  Script to test the LiveView analyzer and fixer on a file that already has all required sections.

  ## Usage

  mix run fix_with_sections_test.exs [--force]
  """

  def run(args) do
    # Parse arguments
    force = Enum.member?(args, "--force")

    # Create a temporary test file with all sections already present
    file_path = "test_with_sections.ex"
    content = """
    defmodule ToucanWeb.UserForgotPasswordLive do
      use ToucanWeb, :live_view

      alias Toucan.Accounts

      # ---------- RENDERING ----------
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

      # ---------- LIFECYCLE CALLBACKS ----------
      def mount(_params, _session, socket) do
        {:ok, assign(socket, form: to_form(%{}, as: "user"))}
      end

      # ---------- EVENT HANDLERS ----------
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

    # Write the test content to file
    File.write!(file_path, content)

    IO.puts("=== Testing LiveView analyzer on file with sections: #{file_path} ===")
    IO.puts("Options: #{if force, do: "force", else: "normal"}")

    # Run analyzer to check for missing sections
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Check for violations
    violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

    # Filter out LiveView section violations
    liveview_violations =
      violations
      |> Enum.filter(fn violation ->
        violation.rule == :live_view_sections &&
          String.contains?(violation.message, "LiveView missing labeled sections")
      end)

    if Enum.empty?(liveview_violations) do
      IO.puts("\n✅ No LiveView section violations found, as expected.")

      # Try force mode if requested
      if force do
        IO.puts("\nTesting force mode to recreate sections...")

        # Sections to add
        sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

        # Apply the forced fixes
        case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, force: true) do
          {:ok, fixed_content} ->
            IO.puts("\n✅ Successfully recreated sections with force mode")

          {:error, reason} ->
            IO.puts("\n❌ Error fixing file: #{reason}")
        end
      end
    else
      IO.puts("\n❌ Found LiveView section violations but none were expected!")
      Enum.each(liveview_violations, fn violation ->
        IO.puts("- #{violation.message}")
      end)
    end

    # Clean up the temporary file
    File.rm(file_path)
  end
end

# Run the test script
FixWithSectionsTest.run(System.argv())
