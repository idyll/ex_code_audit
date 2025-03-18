defmodule FixUserFileTest do
  @moduledoc """
  Script to test the LiveView section fixer on a sample file matching
  the structure of the user's problematic file.

  ## Usage

  mix run fix_user_file_test.exs [--preview] [--force]
  """

  def run(args) do
    # Parse arguments
    preview = Enum.member?(args, "--preview")
    force = Enum.member?(args, "--force")

    # Create a temporary test file matching the user's reported issue
    file_path = "test_user_file.ex"
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

    # Write the test content to file
    File.write!(file_path, content)

    IO.puts("=== Testing LiveView fixer on: #{file_path} ===")
    IO.puts("Options: #{if preview, do: "preview", else: "fix"} #{if force, do: "force", else: ""}")

    # Sections to add
    sections_to_add = ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]

    # In force mode, we directly apply all sections without checking for violations
    if force do
      # Apply or preview the forced fixes
      if preview do
        # Just preview the changes
        case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true, file_path: file_path, force: true) do
          {:ok, preview_text} ->
            IO.puts("\nPreview of fixes (force mode):")
            IO.puts(preview_text)

          {:error, reason} ->
            IO.puts("\nError generating preview: #{reason}")
        end
      else
        # Apply the fixes
        case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, force: true) do
          {:ok, fixed_content} ->
            case File.write(file_path, fixed_content) do
              :ok ->
                IO.puts("\n✅ Successfully fixed file (force mode): #{file_path}")
                IO.puts("  Added sections: #{Enum.join(sections_to_add, ", ")}")

              {:error, reason} ->
                IO.puts("\n❌ Error writing to file: #{reason}")
            end

          {:error, reason} ->
            IO.puts("\n❌ Error fixing file: #{reason}")
        end
      end
    else
      # Regular mode - check for violations first
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
        IO.puts("\nNo LiveView section violations found in the file.")
      else
        # We have violations to fix
        IO.puts("\nFound #{length(liveview_violations)} LiveView section violations.")

        Enum.each(liveview_violations, fn violation ->
          # Extract missing sections from the violation message
          sections_to_add = find_missing_sections(violation)

          # Fix or preview
          if preview do
            # Just preview the changes
            case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add, preview: true, file_path: file_path) do
              {:ok, preview_text} ->
                IO.puts("\nPreview of fixes:")
                IO.puts(preview_text)

              {:error, reason} ->
                IO.puts("\nError generating preview: #{reason}")
            end
          else
            # Apply the fixes
            case ExCodeAudit.Fixers.LiveView.fix_sections(content, sections_to_add) do
              {:ok, fixed_content} ->
                case File.write(file_path, fixed_content) do
                  :ok ->
                    IO.puts("\n✅ Successfully fixed file: #{file_path}")
                    IO.puts("  Added sections: #{Enum.join(sections_to_add, ", ")}")

                  {:error, reason} ->
                    IO.puts("\n❌ Error writing to file: #{reason}")
                end

              {:error, reason} ->
                IO.puts("\n❌ Error fixing file: #{reason}")
            end
          end
        end)
      end
    end

    # Clean up the temporary file
    File.rm(file_path)
  end

  # Extract missing sections from a violation message
  defp find_missing_sections(violation) do
    message = violation.message

    # Extract sections using our updated regex
    case Regex.run(~r/Missing sections: \[(.*?)\]/, message) do
      [_, sections_str] ->
        sections_str
        |> String.split(",")
        |> Enum.map(fn section ->
          # Remove quotes and trim
          section
          |> String.trim()
          |> String.replace(~r/^"/, "")  # Remove leading quote
          |> String.replace(~r/"$/, "")  # Remove trailing quote
        end)

      _ ->
        # Fallback
        ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]
    end
  end
end

# Run the test script
FixUserFileTest.run(System.argv())
