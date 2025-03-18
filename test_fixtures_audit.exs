defmodule TestFixturesAudit do
  @moduledoc """
  Script to test the LiveView analyzer and fixer on test fixtures.

  ## Usage

  mix run test_fixtures_audit.exs [--fix] [--preview] [--force]
  """

  def run(args) do
    # Parse arguments
    preview = Enum.member?(args, "--preview")
    fix = Enum.member?(args, "--fix")
    force = Enum.member?(args, "--force")

    # Create a temporary config file for testing
    config_file = ".code_audit.exs"
    config_content = """
    %{
      scan_paths: ["test/fixtures"],
      excluded_paths: [
        "deps/**",
        "_build/**",
        "lib/**",
        "priv/**",
        ".git/**",
        ".*/**",
        "docs/**",
        "rel/**",
        "assets/node_modules/**"
      ],
      rules: %{
        live_view_sections: %{
          enabled: true,
          required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
          violation_level: :warning
        },
        file_size: %{enabled: false},
        fixture_usage: %{enabled: false},
        repo_calls: %{enabled: false},
        schema_content: %{enabled: false},
        schema_location: %{enabled: false},
        test_coverage: %{enabled: false}
      },
      verbose: false
    }
    """

    # Write the config file
    File.write!(config_file, config_content)

    IO.puts("=== Testing LiveView analyzer on test fixtures ===")
    IO.puts("Options: #{if fix, do: "fix", else: ""} #{if preview, do: "preview", else: ""} #{if force, do: "force", else: ""}")

    # Build the command
    cmd_args = ["code.audit", "--skip-compile"]
    cmd_args = if fix, do: cmd_args ++ ["--fix"], else: cmd_args
    cmd_args = if preview, do: cmd_args ++ ["--preview"], else: cmd_args
    cmd_args = if force, do: cmd_args ++ ["--force"], else: cmd_args

    try do
      # Run the mix task with the desired options
      {output, status} = System.cmd("mix", cmd_args, stderr_to_stdout: true)

      # Output the result summary only
      IO.puts("\nCommand completed with status: #{status}")

      # Exit with the same status code
      status
    after
      # Clean up the temporary file
      File.rm(config_file)
    end
  end
end

# Run the test
status = TestFixturesAudit.run(System.argv())
System.halt(status)
