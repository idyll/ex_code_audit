defmodule TestUserIssue do
  @moduledoc """
  Script to test the LiveView analyzer and fixer specifically for the user's reported issue.
  This script tests two cases:
  1. A LiveView file with properly formatted section headers (should detect them)
  2. A LiveView file without section headers (should report missing sections)
  """

  def run do
    IO.puts("=== Testing analyzer and fixer for user-reported issue ===")

    # Create two test files
    file_with_sections = "test_with_sections.ex"
    file_without_sections = "test_without_sections.ex"

    # Content WITH properly formatted section headers
    content_with = """
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

    # Content WITHOUT section headers (exactly matching user's example)
    content_without = """
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

    # Write the test files
    File.write!(file_with_sections, content_with)
    File.write!(file_without_sections, content_without)

    try do
      # Analyze the file WITH sections
      test_file_with_sections(file_with_sections, content_with)

      # Analyze the file WITHOUT sections
      test_file_without_sections(file_without_sections, content_without)

      # Test the fix functionality
      test_fix_functionality(file_without_sections, content_without)

      # Test force mode
      test_force_mode(file_with_sections, content_with)
    after
      # Clean up test files
      File.rm(file_with_sections)
      File.rm(file_without_sections)
    end
  end

  # Test the analyzer on a file WITH section headers
  defp test_file_with_sections(file_path, content) do
    IO.puts("\n1. Testing analyzer on file WITH section headers")

    # Config for the analyzer
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Run the analyzer
    violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

    if Enum.empty?(violations) do
      IO.puts("   ✅ Success: Analyzer correctly detected all required sections")
    else
      IO.puts("   ❌ Error: Analyzer found violations in a file with proper sections")
    end
  end

  # Test the analyzer on a file WITHOUT section headers
  defp test_file_without_sections(file_path, content) do
    IO.puts("\n2. Testing analyzer on file WITHOUT section headers")

    # Config for the analyzer
    config = %{
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    }

    # Run the analyzer
    violations = ExCodeAudit.Analyzers.LiveView.check(file_path, content, config)

    if Enum.empty?(violations) do
      IO.puts("   ❌ Error: Analyzer failed to detect missing sections")
    else
      IO.puts("   ✅ Success: Analyzer correctly found missing section violations")
    end
  end

  # Test the fix functionality
  defp test_fix_functionality(file_path, content) do
    IO.puts("\n3. Testing fixer to add missing sections to file")

    sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

    # Test the fix functionality
    case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add) do
      {:ok, fixed_content} ->
        IO.puts("   ✅ Success: Fixer added the missing sections")

        # Verify that the analyzer now detects no violations
        config = %{
          required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
          violation_level: :warning
        }

        # Write fixed content to temporary file for verification
        fixed_file = "#{file_path}.fixed"
        File.write!(fixed_file, fixed_content)

        violations = ExCodeAudit.Analyzers.LiveView.check(fixed_file, fixed_content, config)

        if Enum.empty?(violations) do
          IO.puts("   ✅ Success: Analyzer detects no violations in fixed file")
        else
          IO.puts("   ❌ Error: Analyzer still finds violations in fixed file")
        end

        # Clean up
        File.rm(fixed_file)

      {:error, message} ->
        IO.puts("   ❌ Error: Fixer failed to add sections: #{message}")
    end
  end

  # Test force mode - verify it can recreate sections even if they exist
  defp test_force_mode(_file_path, content) do
    IO.puts("\n4. Testing force mode to recreate sections")

    sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

    # Test force mode
    case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, force: true) do
      {:ok, fixed_content} ->
        IO.puts("   ✅ Success: Force mode recreated all sections")

        # Check if sections were actually added
        existing_sections = ExCodeAudit.Fixers.LiveViewTestHelper.find_sections(content)
        fixed_sections = ExCodeAudit.Fixers.LiveViewTestHelper.find_sections(fixed_content)

        section_count_before = length(existing_sections)
        section_count_after = length(fixed_sections)

        if section_count_after > section_count_before do
          IO.puts("   ✅ Success: Force mode added new sections (#{section_count_before} → #{section_count_after})")
        else
          IO.puts("   ❌ Error: Force mode didn't add new sections (#{section_count_before} → #{section_count_after})")
        end

      {:error, message} ->
        IO.puts("   ❌ Error: Force mode failed: #{message}")
    end
  end
end

# Run the tests
TestUserIssue.run()
