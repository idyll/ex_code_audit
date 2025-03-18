# ExCodeAudit Configuration Guide

This guide covers all the configuration options available for ExCodeAudit.

## Configuration Methods

ExCodeAudit can be configured in multiple ways, with each subsequent level overriding the previous:

1. Default configuration built into the package
2. Application configuration in `config/config.exs`
3. Global configuration file in your home directory (`~/.code_audit.yml` or `~/.code_audit.json`)
4. Project-level configuration file (`.code_audit.yml` or `.code_audit.json` in your project root)
5. Command-line options

## Generating a Configuration File

You can generate a sample configuration file using:

```bash
# Generate YAML configuration (default)
mix code.audit.init

# Generate JSON configuration
mix code.audit.init --format=json

# Specify output location
mix code.audit.init --output=custom_config.yml
```

This will create a `.code_audit.yml` or `.code_audit.json` file in your project directory with all available configuration options.

## Configuration File Formats

ExCodeAudit supports both YAML and JSON for configuration files.

### YAML Configuration Example

```yaml
rules:
  schema_location:
    enabled: true
    path: "lib/:app_name/schema/*.ex"
    violation_level: error
  
  schema_content:
    enabled: true
    excludes:
      - "Repo."
    violation_level: warning
  
  live_view_sections:
    enabled: true
    required:
      - "LIFECYCLE CALLBACKS"
      - "EVENT HANDLERS"
      - "RENDERING"
    check_external_templates: true
    check_component_structure: true
    violation_level: warning
  
  file_size:
    enabled: true
    max_lines: 1000
    warning_at: 920
    violation_level: warning
  
  repo_calls:
    enabled: true
    allowed_in:
      - "lib/:app_name/operations/*.ex"
      - "lib/:app_name/queries/*.ex"
    excluded_paths:
      - "priv/repo/migrations/**"
      - "priv/repo/seeds.exs"
      - "lib/:app_name_web/telemetry.ex"
      - "lib/:app_name_web.ex"
    violation_level: warning
  
  test_coverage:
    enabled: true
    min_percentage: 90
    violation_level: error
  
  fixture_usage:
    enabled: true
    allowed: false
    check_factory_exists: true
    violation_level: error

excluded_paths:
  - deps/**
  - _build/**
  - priv/static/**
  - .git/**
```

### JSON Configuration Example

```json
{
  "rules": {
    "schema_location": {
      "enabled": true,
      "path": "lib/:app_name/schema/*.ex",
      "violation_level": "error"
    },
    "schema_content": {
      "enabled": true,
      "excludes": ["Repo."],
      "violation_level": "warning"
    },
    "live_view_sections": {
      "enabled": true,
      "required": ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      "check_external_templates": true,
      "check_component_structure": true,
      "violation_level": "warning"
    },
    "file_size": {
      "enabled": true,
      "max_lines": 1000,
      "warning_at": 920,
      "violation_level": "warning"
    },
    "repo_calls": {
      "enabled": true,
      "allowed_in": ["lib/:app_name/operations/*.ex", "lib/:app_name/queries/*.ex"],
      "excluded_paths": [
        "priv/repo/migrations/**", 
        "priv/repo/seeds.exs",
        "lib/:app_name_web/telemetry.ex",
        "lib/:app_name_web.ex"
      ],
      "violation_level": "warning"
    },
    "test_coverage": {
      "enabled": true,
      "min_percentage": 90,
      "violation_level": "error"
    },
    "fixture_usage": {
      "enabled": true,
      "allowed": false,
      "check_factory_exists": true,
      "violation_level": "error"
    }
  },
  "excluded_paths": [
    "deps/**",
    "_build/**",
    "priv/static/**",
    ".git/**"
  ]
}
```

## Application Configuration

You can also configure ExCodeAudit in your `config/config.exs` file:

```elixir
config :ex_code_audit,
  rules: [
    # Schema rules
    schema_location: [
      enabled: true,
      path: "lib/:app_name/schema/*.ex",
      violation_level: :error
    ],
    schema_content: [
      enabled: true,
      excludes: ["Repo."],
      violation_level: :warning
    ],
    
    # LiveView rules
    live_view_sections: [
      enabled: true,
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      check_external_templates: true,
      check_component_structure: true,
      violation_level: :warning
    ],
    
    # File size rules
    file_size: [
      enabled: true,
      max_lines: 1000,
      warning_at: 920,
      violation_level: :warning
    ],
    
    # Repo calls rules
    repo_calls: [
      enabled: true,
      allowed_in: ["lib/:app_name/operations/*.ex", "lib/:app_name/queries/*.ex"],
      excluded_paths: [
        "priv/repo/migrations/**", 
        "priv/repo/seeds.exs",
        "lib/:app_name_web/telemetry.ex",
        "lib/:app_name_web.ex"
      ],
      violation_level: :warning
    ],

    # Test coverage rules
    test_coverage: [
      enabled: true,
      min_percentage: 90,
      violation_level: :error
    ],

    # Factory usage rules
    fixture_usage: [
      enabled: true,
      allowed: false,
      check_factory_exists: true,
      violation_level: :error
    ]
  ],
  
  # Paths to exclude from analysis
  excluded_paths: [
    "deps/**",
    "_build/**",
    "priv/static/**",
    ".git/**"
  ]
```

## Global vs. Project Configuration

The global configuration located at `~/.code_audit.yml` or `~/.code_audit.json` will be applied to all projects, but can be overridden by project-level configurations.

This is useful for setting your personal preferences that will apply to any project you work on, while still allowing project-specific configurations to take precedence.

## Configuration Variables

In configuration files, you can use the `:app_name` variable which will be replaced with your actual application name at runtime:

```yaml
rules:
  schema_location:
    path: "lib/:app_name/schema/*.ex"
```

If your application is named `my_app`, this will be expanded to `lib/my_app/schema/*.ex` at runtime.

## Common Configuration Options

There are some configuration options common to all rules:

- `enabled`: Boolean to enable/disable the rule
- `violation_level`: Either `warning` or `error` to control severity

## Global Excluded Paths

You can specify paths to exclude from all rule checks:

```elixir
config :ex_code_audit,
  excluded_paths: [
    "deps/**",
    "_build/**",
    "priv/static/**",
    ".git/**"
  ]
```

## Rule-Specific Configuration

For detailed information on each rule's configuration options, see the rule-specific documentation:

- [File Size Rule](rules/file_size.md)
- [Schema Location Rule](rules/schema_location.md)
- [Schema Content Rule](rules/schema_content.md)
- [LiveView Sections Rule](rules/live_view_sections.md)
- [Repository Calls Rule](rules/repo_calls.md)
- [Test Coverage Rule](rules/test_coverage.md)
- [Factory Usage Rule](rules/fixture_usage.md)

## Overriding Rules per Directory

*Note: This is a planned feature and may not be available in the current version.*

You can override rule configurations for specific directories in your project:

```yaml
rules:
  file_size:
    max_lines: 1000
    
directory_overrides:
  "lib/my_app/legacy/":
    file_size:
      max_lines: 1500
      violation_level: warning
```

This would allow larger files in the legacy directory without triggering errors.

## Configuration Best Practices

1. **Start with the default configuration**: Use `mix code.audit.init` to generate a base config file
2. **Adjust rules to your project**: Modify the generated config to match your project's needs
3. **Version control your config**: Include your `.code_audit.yml` or `.code_audit.json` in version control
4. **Use global config sparingly**: Reserve global configs for personal preferences, not project requirements
5. **Review periodically**: Revisit your configuration as your project evolves
