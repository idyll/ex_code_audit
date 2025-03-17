defmodule Mix.Tasks.Code.Audit.Init do
  @moduledoc """
  A Mix task to generate a sample configuration file for ExCodeAudit.

  ## Usage

      # Generate YAML configuration
      mix code.audit.init

      # Generate JSON configuration
      mix code.audit.init --format=json

      # Specify output location
      mix code.audit.init --output=.code_audit.yml
  """

  use Mix.Task

  @shortdoc "Generates a sample configuration file for code audits"

  @switches [
    format: :string,
    output: :string
  ]

  @default_options [
    format: "yaml",
    output: nil
  ]

  @sample_config %{
    rules: %{
      schema_location: %{
        enabled: true,
        path: "lib/:app_name/schema/*.ex",
        violation_level: :error
      },
      schema_content: %{
        enabled: true,
        excludes: ["Repo."],
        violation_level: :warning
      },
      live_view_sections: %{
        enabled: true,
        required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
        check_external_templates: true,
        check_component_structure: true,
        violation_level: :warning
      },
      file_size: %{
        enabled: true,
        max_lines: 1000,
        warning_at: 920,
        violation_level: :warning
      },
      repo_calls: %{
        enabled: true,
        allowed_in: ["lib/:app_name/operations/*.ex", "lib/:app_name/queries/*.ex"],
        violation_level: :warning
      },
      test_coverage: %{
        enabled: true,
        min_percentage: 90,
        violation_level: :error
      },
      fixture_usage: %{
        enabled: true,
        allowed: false,
        check_factory_exists: true,
        violation_level: :error
      }
    },
    excluded_paths: [
      "deps/**",
      "_build/**",
      "priv/static/**",
      ".git/**"
    ]
  }

  @impl true
  def run(args) do
    # Parse command-line arguments
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    # Merge with default options
    opts = Keyword.merge(@default_options, opts)

    # Generate and write the config file
    generate_config_file(opts)
  end

  defp generate_config_file(opts) do
    format = Keyword.get(opts, :format)
    output = Keyword.get(opts, :output) || default_output_path(format)

    content = generate_config_content(format)

    case File.write(output, content) do
      :ok ->
        Mix.shell().info("Configuration file generated at: #{output}")

      {:error, reason} ->
        Mix.raise("Failed to write configuration file: #{inspect(reason)}")
    end
  end

  defp default_output_path("json"), do: ".code_audit.json"
  defp default_output_path(_), do: ".code_audit.yml"

  defp generate_config_content("json") do
    # Using Jason for JSON generation
    Jason.encode!(@sample_config, pretty: true)
  end

  defp generate_config_content(_) do
    # Using YamlElixir for YAML generation
    # First convert atoms to strings in rule names and violation levels
    config =
      @sample_config
      |> prepare_for_yaml()

    # Convert the prepared config to YAML format using manual formatting
    # since YamlElixir doesn't have a direct dump! function
    yaml_content = generate_yaml(config)
    yaml_content
  end

  # Manually generate YAML content from a nested map
  defp generate_yaml(map) when is_map(map) do
    map
    |> Enum.map_join("\n", fn {key, value} ->
      if is_map(value) || (is_list(value) && value != [] && is_map(hd(value))) do
        "#{key}:\n#{indent(generate_yaml(value))}"
      else
        "#{key}: #{format_yaml_value(value)}"
      end
    end)
  end

  defp generate_yaml(list) when is_list(list) do
    if Enum.all?(list, &is_binary/1) do
      # Simple list of strings
      Enum.map_join(list, "\n", fn item -> "- #{item}" end)
    else
      # Complex list
      Enum.map_join(list, "\n", fn item -> "- #{format_yaml_value(item)}" end)
    end
  end

  defp indent(text) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> "  #{line}" end)
  end

  defp format_yaml_value(value) when is_binary(value), do: "\"#{value}\""
  defp format_yaml_value(value) when is_atom(value), do: "#{value}"
  defp format_yaml_value(value) when is_integer(value), do: "#{value}"
  defp format_yaml_value(value) when is_boolean(value), do: "#{value}"

  defp format_yaml_value(value) when is_list(value) do
    if value == [] do
      "[]"
    else
      "\n#{indent(generate_yaml(value))}"
    end
  end

  defp format_yaml_value(value) when is_map(value) do
    "\n#{indent(generate_yaml(value))}"
  end

  # Prepare configuration for YAML serialization by converting atoms to strings
  defp prepare_for_yaml(config) when is_map(config) do
    Enum.map(config, fn {key, value} -> {to_string(key), prepare_for_yaml(value)} end)
    |> Enum.into(%{})
  end

  defp prepare_for_yaml(config) when is_list(config) do
    Enum.map(config, &prepare_for_yaml/1)
  end

  defp prepare_for_yaml(value) when is_atom(value) do
    to_string(value)
  end

  defp prepare_for_yaml(value), do: value
end
