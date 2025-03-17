defmodule ExCodeAudit.Config do
  @moduledoc """
  Handles configuration for ExCodeAudit.

  This module is responsible for loading, validating, and providing access to
  the configuration values used throughout the application.

  Configuration can be loaded from:
  - Application config (config/config.exs)
  - YAML file (.code_audit.yml or .code_audit.yaml)
  - JSON file (.code_audit.json)
  - Command-line options

  Priority order (highest to lowest):
  1. Command-line options
  2. Project-level config file (.code_audit.yml or .code_audit.json in project root)
  3. Global config file (~/.code_audit.yml or ~/.code_audit.json)
  4. Application config (config/config.exs)
  5. Default config
  """

  @type rule_config :: %{
          required(:enabled) => boolean(),
          required(:violation_level) => :warning | :error,
          optional(atom()) => any()
        }

  @type t :: %{
          rules: %{atom() => rule_config()},
          excluded_paths: [String.t()],
          options: map()
        }

  @default_excluded_paths [
    "deps/**",
    "_build/**",
    "priv/static/**",
    ".git/**",
    # Any hidden directory
    ".*/**",
    # Any hidden directory at root
    ".*/",
    # Test directory
    "test/**",
    # Documentation directory
    "docs/**",
    # Release directory
    "rel/**",
    # Node modules
    "assets/node_modules/**"
  ]

  @default_config %{
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
        excluded_paths: [
          "priv/repo/migrations/**",
          "priv/repo/seeds.exs",
          ".*/**/priv/repo/migrations/**",
          ".*/**/priv/repo/seeds.exs",
          "lib/:app_name_web/telemetry.ex",
          "lib/:app_name_web.ex"
        ],
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
    excluded_paths: @default_excluded_paths,
    options: %{
      strict: false
    }
  }

  @config_filenames [
    ".code_audit.yml",
    ".code_audit.yaml",
    ".code_audit.json"
  ]

  @doc """
  Loads the configuration from Application config and potential config files.

  Merges the default configuration with user-provided configuration in the following order:
  1. Default config
  2. Application config
  3. Global config file
  4. Project-level config file
  5. Command-line options

  ## Parameters

  - `opts`: Additional options to override the loaded configuration

  ## Returns

  A map containing the complete configuration

  ## Examples

      iex> config = ExCodeAudit.Config.load()
      iex> is_map(config.rules)
      true
      iex> is_list(config.excluded_paths)
      true
      iex> config.options.strict
      false
  """
  @spec load(Keyword.t()) :: t()
  def load(opts \\ []) do
    # Start with default config
    config = @default_config

    # Apply app configuration
    config = apply_app_config(config)

    # Apply global config file if it exists
    config = apply_global_config_file(config)

    # Apply project config file if it exists
    config = apply_project_config_file(config)

    # Apply command-line options
    config = apply_options(config, opts)

    config
  end

  @doc """
  Gets a rule configuration by name.

  ## Parameters

  - `config`: The configuration map
  - `rule_name`: The name of the rule to get

  ## Returns

  The rule configuration map or nil if not found

  ## Examples

      iex> config = ExCodeAudit.Config.load()
      iex> rule = ExCodeAudit.Config.get_rule(config, :file_size)
      iex> rule.enabled
      true
      iex> rule.max_lines > 0
      true
  """
  @spec get_rule(t(), atom()) :: rule_config() | nil
  def get_rule(config, rule_name) do
    get_in(config, [:rules, rule_name])
  end

  @doc """
  Checks if a rule is enabled.

  ## Parameters

  - `config`: The configuration map
  - `rule_name`: The name of the rule to check

  ## Returns

  True if the rule is enabled, false otherwise

  ## Examples

      iex> config = ExCodeAudit.Config.load()
      iex> ExCodeAudit.Config.rule_enabled?(config, :file_size)
      true
  """
  @spec rule_enabled?(t(), atom()) :: boolean()
  def rule_enabled?(config, rule_name) do
    case get_rule(config, rule_name) do
      %{enabled: enabled} -> enabled
      _ -> false
    end
  end

  # Apply configuration from Application config
  defp apply_app_config(config) do
    app_config = Application.get_all_env(:ex_code_audit)

    # Deep merge the application config with our default config
    config
    |> deep_merge(%{rules: Keyword.get(app_config, :rules, %{})})
    |> deep_merge(%{excluded_paths: Keyword.get(app_config, :excluded_paths, [])})
  end

  # Load and apply configuration from global config file (~/.code_audit.yml or similar)
  defp apply_global_config_file(config) do
    home_dir = System.user_home()

    global_config_paths =
      @config_filenames
      |> Enum.map(fn filename -> Path.join(home_dir, filename) end)

    case find_and_load_config_file(global_config_paths) do
      {:ok, file_config} -> deep_merge(config, file_config)
      _ -> config
    end
  end

  # Load and apply configuration from project-level config file (.code_audit.yml or similar)
  defp apply_project_config_file(config) do
    case find_and_load_config_file(@config_filenames) do
      {:ok, file_config} -> deep_merge(config, file_config)
      _ -> config
    end
  end

  # Find the first available config file from a list of paths and load it
  defp find_and_load_config_file(paths) do
    paths
    |> Enum.find(&File.exists?/1)
    |> case do
      nil -> {:error, :not_found}
      path -> load_config_file(path)
    end
  end

  # Load configuration from a file based on its extension
  defp load_config_file(path) do
    case Path.extname(path) do
      ext when ext in [".yml", ".yaml"] -> load_yaml_config(path)
      ".json" -> load_json_config(path)
      _ -> {:error, :unsupported_format}
    end
  end

  # Load configuration from a YAML file
  defp load_yaml_config(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, content} -> {:ok, normalize_config(content)}
      {:error, _reason} = error -> error
    end
  end

  # Load configuration from a JSON file
  defp load_json_config(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, parsed} -> {:ok, normalize_config(parsed)}
          {:error, _reason} = error -> error
        end

      {:error, _reason} = error ->
        error
    end
  end

  # Normalize the configuration loaded from YAML or JSON
  defp normalize_config(config) when is_map(config) do
    config = for {key, value} <- config, into: %{}, do: {String.to_atom(key), value}

    if Map.has_key?(config, :rules) do
      rules =
        for {rule_name, rule_config} <- config.rules, into: %{} do
          {String.to_atom(rule_name), normalize_rule_config(rule_config)}
        end

      %{config | rules: rules}
    else
      config
    end
  end

  defp normalize_config(config), do: config

  # Normalize rule configuration by converting string keys to atoms
  defp normalize_rule_config(rule_config) when is_map(rule_config) do
    for {key, value} <- rule_config, into: %{} do
      {String.to_atom(key), normalize_value(key, value)}
    end
  end

  defp normalize_rule_config(rule_config), do: rule_config

  # Normalize specific values based on the key
  defp normalize_value("violation_level", value) when is_binary(value) do
    String.to_atom(value)
  end

  defp normalize_value(_key, value), do: value

  # Apply command-line options to the configuration
  defp apply_options(config, opts) do
    options = Map.new(opts)

    # Update the options section of our config
    %{config | options: Map.merge(config.options, options)}
  end

  # Deep merge two maps
  defp deep_merge(left, right) do
    Map.merge(left, right, fn
      _k, %{} = l, %{} = r -> deep_merge(l, r)
      _k, _l, r -> r
    end)
  end
end
