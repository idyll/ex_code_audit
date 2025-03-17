defmodule ExCodeAudit.ConfigTest do
  use ExUnit.Case, async: true
  doctest ExCodeAudit.Config

  alias ExCodeAudit.Config

  describe "load/1" do
    setup do
      # Save the original environment
      original_env = Application.get_all_env(:ex_code_audit)

      # Create temporary config files
      tmp_dir = System.tmp_dir()
      yaml_path = Path.join(tmp_dir, ".code_audit.yml")
      json_path = Path.join(tmp_dir, ".code_audit.json")

      # Write YAML config
      yaml_content = """
      rules:
        file_size:
          enabled: true
          max_lines: 500
          warning_at: 450
          violation_level: warning
        schema_location:
          enabled: false
      excluded_paths:
        - tmp/**
        - test/fixtures/**
      """

      File.write!(yaml_path, yaml_content)

      # Write JSON config
      json_content = """
      {
        "rules": {
          "file_size": {
            "enabled": true,
            "max_lines": 600,
            "warning_at": 550,
            "violation_level": "warning"
          },
          "live_view_sections": {
            "enabled": false
          }
        },
        "excluded_paths": [
          "tmp/**",
          "scripts/**"
        ]
      }
      """

      File.write!(json_path, json_content)

      on_exit(fn ->
        # Restore the original environment
        Enum.each(original_env, fn {k, v} ->
          Application.put_env(:ex_code_audit, k, v)
        end)

        # Clean up temporary files
        File.rm(yaml_path)
        File.rm(json_path)
      end)

      %{yaml_path: yaml_path, json_path: json_path, tmp_dir: tmp_dir}
    end

    test "loads default configuration" do
      config = Config.load()

      assert is_map(config)
      assert is_map(config.rules)
      assert is_list(config.excluded_paths)

      # Check default values
      file_size = Config.get_rule(config, :file_size)
      assert file_size.enabled
      assert file_size.max_lines == 1000
      assert file_size.warning_at == 920
    end

    test "loads configuration from YAML file", %{yaml_path: yaml_path} do
      # Copy the YAML file to the current directory
      File.cp!(yaml_path, ".code_audit.yml")

      on_exit(fn -> File.rm(".code_audit.yml") end)

      config = Config.load()

      # Check if YAML config was loaded
      file_size = Config.get_rule(config, :file_size)
      assert file_size.enabled
      assert file_size.max_lines == 500
      assert file_size.warning_at == 450

      # Check if disabled rule was applied
      schema_location = Config.get_rule(config, :schema_location)
      refute schema_location.enabled

      # Check excluded paths
      assert "tmp/**" in config.excluded_paths
      assert "test/fixtures/**" in config.excluded_paths
    end

    test "loads configuration from JSON file", %{json_path: json_path} do
      # Copy the JSON file to the current directory
      File.cp!(json_path, ".code_audit.json")

      on_exit(fn -> File.rm(".code_audit.json") end)

      config = Config.load()

      # Check if JSON config was loaded
      file_size = Config.get_rule(config, :file_size)
      assert file_size.enabled
      assert file_size.max_lines == 600
      assert file_size.warning_at == 550

      # Check if disabled rule was applied
      live_view_sections = Config.get_rule(config, :live_view_sections)
      refute live_view_sections.enabled

      # Check excluded paths
      assert "tmp/**" in config.excluded_paths
      assert "scripts/**" in config.excluded_paths
    end

    test "command-line options override file configuration", %{yaml_path: yaml_path} do
      # Copy the YAML file to the current directory
      File.cp!(yaml_path, ".code_audit.yml")

      on_exit(fn -> File.rm(".code_audit.yml") end)

      config = Config.load(strict: true, only_categories: [:file_size])

      # Check if command-line options were applied
      assert config.options.strict
      assert config.options.only_categories == [:file_size]

      # File config should still be applied for other settings
      file_size = Config.get_rule(config, :file_size)
      assert file_size.max_lines == 500
    end

    test "rule_enabled? returns correct values" do
      config = %{
        rules: %{
          enabled_rule: %{enabled: true},
          disabled_rule: %{enabled: false},
          missing_rule: %{}
        }
      }

      assert Config.rule_enabled?(config, :enabled_rule)
      refute Config.rule_enabled?(config, :disabled_rule)
      refute Config.rule_enabled?(config, :missing_rule)
      refute Config.rule_enabled?(config, :nonexistent_rule)
    end
  end

  describe "get_rule/2" do
    test "gets a rule by name" do
      config = Config.load()

      rule_config = Config.get_rule(config, :file_size)

      assert is_map(rule_config)
      assert rule_config.enabled == true
      assert is_integer(rule_config.max_lines)
      assert is_integer(rule_config.warning_at)
      assert rule_config.violation_level in [:warning, :error]
    end

    test "returns nil for non-existent rule" do
      config = Config.load()

      assert Config.get_rule(config, :non_existent_rule) == nil
    end
  end

  describe "rule_enabled?/2" do
    test "returns true for enabled rules" do
      config = Config.load()

      assert Config.rule_enabled?(config, :file_size) == true
    end

    test "returns false for disabled rules" do
      config = %{Config.load() | rules: %{file_size: %{enabled: false}}}

      assert Config.rule_enabled?(config, :file_size) == false
    end

    test "returns false for non-existent rules" do
      config = Config.load()

      assert Config.rule_enabled?(config, :non_existent_rule) == false
    end
  end
end
