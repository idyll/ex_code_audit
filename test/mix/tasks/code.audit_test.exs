defmodule Mix.Tasks.Code.AuditTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Code.Audit

  setup do
    # Create a temporary directory for test files
    tmp_dir = System.tmp_dir!() |> Path.join("ex_code_audit_test_#{:rand.uniform(1000)}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      # Clean up temporary files
      File.rm_rf!(tmp_dir)
    end)

    {:ok, %{tmp_dir: tmp_dir}}
  end

  test "fix command identifies and fixes missing sections in LiveView file", %{tmp_dir: tmp_dir} do
    # Create a sample LiveView file with missing sections
    live_view_content = """
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

    file_path = Path.join(tmp_dir, "user_forgot_password_live.ex")
    File.write!(file_path, live_view_content)

    # Test directly with the LiveView analyzer and fixer
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Run the analyzer to check for violations
    violations = ExCodeAudit.Analyzers.LiveView.check(file_path, live_view_content, config)

    # There should be violations for missing sections
    refute Enum.empty?(violations)

    # Find the LiveView section violations
    section_violations = Enum.filter(violations, fn v ->
      v.rule == :live_view_sections &&
      String.contains?(v.message, "LiveView missing labeled sections")
    end)

    # There should be at least one section violation
    refute Enum.empty?(section_violations)

    # Extract the sections to add from the violation
    violation = hd(section_violations)
    sections_to_add = extract_sections_from_violation(violation.message)

    # The sections list should contain our required sections
    assert "LIFECYCLE CALLBACKS" in sections_to_add
    assert "EVENT HANDLERS" in sections_to_add
    assert "RENDERING" in sections_to_add

    # Generate a preview of the fix
    {:ok, preview} = ExCodeAudit.Fixers.LiveView.fix_sections(
      live_view_content,
      sections_to_add,
      preview: true,
      file_path: file_path
    )

    # The preview should include all three sections
    assert String.contains?(preview, "LIFECYCLE CALLBACKS")
    assert String.contains?(preview, "EVENT HANDLERS")
    assert String.contains?(preview, "RENDERING")
  end

  # Helper function to extract section names from violation message
  defp extract_sections_from_violation(message) do
    case Regex.run(~r/Missing sections: \[(.*?)\]/, message) do
      [_, sections_str] ->
        sections_str
        |> String.split(",")
        |> Enum.map(fn section ->
          section
          |> String.trim()
          |> String.replace(~r/^"/, "")  # Remove leading quote
          |> String.replace(~r/"$/, "")  # Remove trailing quote
        end)
      _ ->
        []
    end
  end
end
