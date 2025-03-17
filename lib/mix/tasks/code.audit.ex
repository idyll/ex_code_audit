defmodule Mix.Tasks.Code.Audit do
  @moduledoc """
  A Mix task to run code audits on Phoenix projects.

  ## Usage

      # Basic usage
      mix code.audit

      # Strict mode (errors cause non-zero exit)
      mix code.audit --strict

      # Specific rule categories
      mix code.audit --only=schema,live_view

      # Output format
      mix code.audit --format=json

      # Output to file
      mix code.audit --output=audit_results.json

      # Verbose mode
      mix code.audit --verbose

      # Skip compiler warnings check
      mix code.audit --skip-compile

      # Check test coverage against a minimum percentage
      mix code.audit --with-coverage

      # Scan specific paths
      mix code.audit --scan=lib,test

      # Show details
      mix code.audit --details
  """

  use Mix.Task

  alias ExCodeAudit.{Config, Runner, Reporters, Violation}

  @shortdoc "Runs code audits on Phoenix projects"

  @switches [
    strict: :boolean,
    only: :string,
    format: :string,
    output: :string,
    verbose: :boolean,
    skip_compile: :boolean,
    with_coverage: :boolean,
    scan: :string,
    details: :boolean
  ]

  @impl true
  def run(args) do
    # Parse command-line arguments
    opts = parse_args(args)

    # Load configuration with command-line options
    config = Config.load(opts)

    # Load coverage data if requested
    config =
      if opts[:with_coverage] do
        coverage_data = load_coverage_data()

        # Add coverage data to the test_coverage rule config
        update_in(config, [:rules, :test_coverage], fn rule_config ->
          rule_config
          |> Map.put(:coverage_data, coverage_data)
          |> Map.put(:check_test_existence, true)
        end)
      else
        config
      end

    # Run the audit
    violations = Runner.run(config)

    # Check for compiler warnings unless skipped
    violations =
      unless Map.get(opts, :skip_compile) do
        compiler_violations = check_compiler_warnings()
        violations ++ compiler_violations
      else
        violations
      end

    # Report the results based on the format option
    report_results(violations, config, opts)

    # Exit with non-zero code if in strict mode and there are errors
    if opts[:strict] && Runner.has_errors?(violations) do
      System.halt(1)
    end
  end

  # Report results based on the format option
  defp report_results(violations, _config, opts) do
    case opts[:format] do
      "console" ->
        Reporters.Console.report(violations, opts)

      "json" ->
        Reporters.Json.report(violations, opts)

      # Add more formats here as they are implemented
      # "github" -> Reporters.Github.report(violations, opts)

      format ->
        Mix.raise("Unsupported format: #{format}")
    end
  end

  # Check for compiler warnings
  defp check_compiler_warnings do
    Mix.shell().info("Checking for compiler warnings...")

    # Create a temporary file to capture the output
    {output, exit_code} =
      System.cmd("mix", ["compile", "--warnings-as-errors", "--force"], stderr_to_stdout: true)

    # Parse the output for warnings
    parse_compiler_output(output, exit_code)
  end

  # Parse the compiler output for warnings
  defp parse_compiler_output(output, exit_code) do
    # If exit code is 0, there were no warnings
    if exit_code == 0 do
      []
    else
      # Split by lines and look for warning patterns
      warnings =
        output
        |> String.split("\n")
        |> Enum.filter(&(String.contains?(&1, "warning:") || String.contains?(&1, "error:")))
        |> Enum.map(&parse_warning_line/1)
        |> Enum.reject(&is_nil/1)

      # Group warnings by file
      warnings
      |> Enum.group_by(& &1.file)
      |> Enum.map(fn {file, file_warnings} ->
        message = "Compiler warnings found in file"
        details = Enum.map_join(file_warnings, "\n   ", &"#{&1.line}: #{&1.message}")

        Violation.new(
          "#{message}\n   #{details}",
          file,
          level: :error,
          rule: :compiler_warnings
        )
      end)
    end
  end

  # Parse a warning line into a structured format
  defp parse_warning_line(line) do
    # Example line: lib/my_app/user.ex:25: warning: unused variable `x`
    case Regex.run(~r/([^:]+):(\d+): (warning|error): (.+)/, line) do
      [_, file, line_str, _type, message] ->
        %{
          file: file,
          line: String.to_integer(line_str),
          message: message
        }

      _ ->
        nil
    end
  end

  # Load coverage data from excoveralls
  defp load_coverage_data do
    Mix.shell().info("Loading test coverage data...")

    # Check if excoveralls is installed
    if Code.ensure_loaded?(Excoveralls) do
      # Try to load the coverage.json file
      coverage_file = "cover/excoveralls.json"

      if File.exists?(coverage_file) do
        case File.read(coverage_file) do
          {:ok, content} ->
            parse_coverage_data(content)

          _ ->
            Mix.shell().info("Could not read coverage data. Running excoveralls...")
            run_excoveralls()
        end
      else
        Mix.shell().info("No coverage data found. Running excoveralls...")
        run_excoveralls()
      end
    else
      Mix.shell().info("Excoveralls not found. Test coverage checking will be limited.")
      %{}
    end
  end

  # Run excoveralls to generate coverage data
  defp run_excoveralls do
    result = Mix.shell().cmd("mix coveralls.json", quiet: true)

    if result == 0 && File.exists?("cover/excoveralls.json") do
      {:ok, content} = File.read("cover/excoveralls.json")
      parse_coverage_data(content)
    else
      Mix.shell().error("Failed to generate coverage data.")
      %{}
    end
  end

  # Parse the coverage JSON data
  defp parse_coverage_data(json_content) do
    case Jason.decode(json_content) do
      {:ok, data} ->
        # Extract the source files and their coverage data
        case data do
          %{"source_files" => source_files} ->
            # Transform the data into a map of file path to line coverage
            Enum.reduce(source_files, %{}, fn file, acc ->
              coverage = parse_file_coverage(file)
              Map.put(acc, file["name"], coverage)
            end)

          _ ->
            Mix.shell().error("Invalid coverage data format.")
            %{}
        end

      _ ->
        Mix.shell().error("Could not parse coverage data.")
        %{}
    end
  end

  # Parse coverage data for a single file
  defp parse_file_coverage(file) do
    coverage = file["coverage"]

    # Create a map of line number to coverage count
    Enum.with_index(coverage, 1)
    |> Enum.reduce(%{}, fn {count, line}, acc ->
      # Skip null entries (non-code lines)
      if count != nil do
        Map.put(acc, line, count)
      else
        acc
      end
    end)
  end

  # Parse command-line arguments
  defp parse_args(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    # Apply defaults for missing options
    default_options = %{
      strict: false,
      format: "console",
      verbose: false,
      skip_compile: false,
      with_coverage: false
    }

    opts =
      opts
      |> Map.new()
      |> Map.merge(default_options, fn _k, v1, _v2 -> v1 end)
      |> parse_format_option()
      |> parse_only_option()
      |> parse_scan_option()

    opts
  end

  # Parse the scan option
  defp parse_scan_option(opts) do
    if Map.has_key?(opts, :scan) do
      scan_paths = opts.scan |> String.split(",") |> Enum.map(&String.trim/1)
      Map.put(opts, :scan_paths, scan_paths)
    else
      opts
    end
  end

  # Parse the format option
  defp parse_format_option(opts) do
    if Map.has_key?(opts, :format) do
      # Validate the format
      case opts.format do
        format when format in ["console", "json"] ->
          opts

        format ->
          Mix.raise("Unsupported format: #{format}")
      end
    else
      # Default format is console
      Map.put(opts, :format, "console")
    end
  end

  # Parse the only option
  defp parse_only_option(opts) do
    if Map.has_key?(opts, :only) do
      # Split the comma-separated list of rule categories
      categories =
        opts.only
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_atom/1)

      # Add the categories to the options
      Map.put(opts, :only_categories, categories)
    else
      opts
    end
  end
end
