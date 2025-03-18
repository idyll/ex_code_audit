# ExCodeAudit

## Core Features

1. Directory structure validation
2. File size limit enforcement
3. Module content analysis
4. Section labeling validation in LiveViews
5. Repository call detection
6. Testing coverage validation
7. Configuration via a flexible config file
8. Command-line interface with reporting options
9. CI integration with exit codes
10. Compiler warnings detection

## Auto-Fix Features

ExCodeAudit includes the ability to automatically fix certain issues it detects. Currently, the tool supports:

### LiveView Section Labels

The tool can automatically add missing LiveView section labels:

```bash
# Auto-fix LiveView section issues
mix code.audit --fix

# Preview the fixes without applying them
mix code.audit --fix --preview
```

When using the `--preview` option, the tool will display:

1. The files with issues
2. A diff-style preview of the changes that will be made
3. The exact line numbers where changes will be applied
4. File paths with line numbers (e.g., `lib/my_app_web/live/user_live.ex:42`) for easy navigation

Example preview output:

```
## Insert LIFECYCLE CALLBACKS at line 6:
  3: 
  4:   def mount(_params, _session, socket) do
  5:     {:ok, assign(socket, count: 0)}
  6:   end
+ 6: # LIFECYCLE CALLBACKS
  lib/my_app_web/live/user_live.ex:6
  6: 
  7:   def handle_event("increment", _, socket) do
  8:     {:noreply, assign(socket, count: socket.assigns.count + 1)}
```

This format makes it easy to see exactly where changes will be made and directly copy the file path with line number for navigation in your editor.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_code_audit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_code_audit, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

## Usage

### Basic Usage

To run the code audit with default settings:

```bash
mix code.audit
```

This will scan your codebase for violations of the configured rules and output the results to the console.

### Options

The following command-line options are available:

- `--strict`: Exit with a non-zero code if any errors are found (useful for CI)
- `--format=<format>`: Output format, either "console" (default) or "json"
- `--output=<file>`: Write the output to a file instead of stdout
- `--verbose`: Show more detailed information about violations
- `--only=<rule1,rule2>`: Only run specific rules (comma-separated list)
- `--skip-compile`: Skip checking for compiler warnings
- `--with-coverage`: Check test coverage against the configured minimum percentage
- `--fix`: Auto-fix certain issues (currently supports LiveView section labels)
- `--preview`: Preview fixes without applying them (use with `--fix`)
- `--force`: Force recreation of headers even if they exist (use with `--fix`)

Examples:

```bash
# Run in strict mode (exit with error if violations found)
mix code.audit --strict

# Output in JSON format
mix code.audit --format=json

# Write output to a file
mix code.audit --output=audit_results.json

# Only run specific rules
mix code.audit --only=file_size,schema_location

# Verbose output
mix code.audit --verbose

# Skip compiler warnings check
mix code.audit --skip-compile

# Include test coverage checks
mix code.audit --with-coverage

# Auto-fix LiveView section issues
mix code.audit --fix

# Preview the fixes without applying them
mix code.audit --fix --preview

# Force recreation of sections even if they exist
mix code.audit --fix --force
```

### Configuration

ExCodeAudit can be configured in multiple ways, with each subsequent level overriding the previous:

1. Default configuration built into the package
2. Application configuration in `config/config.exs`
3. Global configuration file in your home directory (`~/.code_audit.yml` or `~/.code_audit.json`)
4. Project-level configuration file (`.code_audit.yml` or `.code_audit.json` in your project root)
5. Command-line options

#### Generating a Configuration File

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

#### Configuration File Format

ExCodeAudit supports both YAML and JSON for configuration files. Here's an example of a YAML configuration:

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

Or as JSON:

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
      "excluded_paths": ["priv/repo/migrations/**", "priv/repo/seeds.exs"],
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

#### Application Configuration

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
      excluded_paths: ["priv/repo/migrations/**", "priv/repo/seeds.exs"],
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

## Rule Configuration Options

### 1. file_size

Checks file sizes against configured limits.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `max_lines` | integer | `1000` | Maximum allowed lines (error if exceeded) |
| `warning_at` | integer | `920` | Warning threshold (90% of max by default) |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

### 2. schema_location

Checks that schema files are in the proper location.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `path` | string | `"lib/:app_name/schema/*.ex"` | The expected path pattern for schema files |
| `violation_level` | atom | `:error` | Level for violations (`:warning` or `:error`) |

### 3. schema_content

Checks what schema files contain.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `excludes` | list | `["Repo."]` | List of patterns that should not be in schema files |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

### 4. live_view_sections

Checks for proper section labels in LiveView modules.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `required` | list | `["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]` | List of required section labels |
| `check_external_templates` | boolean | `true` | Whether to check for external templates |
| `check_component_structure` | boolean | `true` | Whether to check component structure |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

**Note**: This analyzer automatically excludes `{app_name}_web.ex` files from analysis as they typically define macros rather than actual LiveView components.

For component structure checking, the analyzer validates:

- Use of embedded HEEx templates
- Presence of an update callback in stateful components
- Documentation of component props, which can be done in any of these ways:
  - Using `@moduledoc` with a "## Props" section
  - Using `@moduledoc` with `{:prop, ...}` syntax
  - Using `@doc` with `{:prop, ...}` syntax

### 5. repo_calls

Checks for repository calls in inappropriate modules.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `allowed_in` | list | `["lib/:app_name/operations/*.ex", "lib/:app_name/queries/*.ex"]` | List of path patterns where repo calls are allowed |
| `excluded_paths` | list | `["priv/repo/migrations/**", "priv/repo/seeds.exs", "lib/:app_name_web/telemetry.ex", "lib/:app_name_web.ex"]` | List of paths to exclude from this rule |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

**Note**: This analyzer automatically excludes migration files, seed files, telemetry files, and `{app_name}_web.ex` files, as these commonly need to make repository calls.

### 6. test_coverage

Checks for test coverage of modules.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `min_percentage` | integer | `90` | Minimum required coverage percentage |
| `violation_level` | atom | `:error` | Level for violations (`:warning` or `:error`) |

### 7. fixture_usage

Checks for proper factory usage in tests.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `allowed` | boolean | `false` | Whether fixtures are allowed in tests |
| `check_factory_exists` | boolean | `true` | Whether to check for the existence of a Factory module |
| `violation_level` | atom | `:error` | Level for violations (`:warning` or `:error`) |

## Documentation

Comprehensive documentation is available in the [docs](docs/) directory:

- [Usage Guide](docs/usage.md) - Detailed usage instructions and examples
- [Configuration Guide](docs/configuration.md) - How to configure ExCodeAudit
- [Rule Descriptions](docs/rules/index.md) - Details about each rule

For hex documentation, visit [https://hexdocs.pm/ex_code_audit](https://hexdocs.pm/ex_code_audit).

## Project Structure

```
lib/
├── code_audit/
│   ├── analyzers/          # Different code analyzers
│   │   ├── schema.ex       # Schema structure analyzer
│   │   ├── live_view.ex    # LiveView structure analyzer
│   │   ├── file_size.ex    # File size analyzer
│   │   ├── repo_calls.ex   # Repository call analyzer
│   │   ├── test_coverage.ex # Test coverage analyzer
│   │   └── factory.ex      # Factory usage analyzer
│   ├── reporters/          # Output formatting modules
│   │   ├── console.ex      # Console output
│   │   ├── json.ex         # JSON output
│   │   └── github.ex       # GitHub Action annotations
│   ├── rules/              # Rule definitions
│   │   ├── rule.ex         # Base rule behavior
│   │   └── rules.ex        # Collection of rules
│   ├── config.ex           # Configuration handling
│   ├── violation.ex        # Violation struct
│   └── runner.ex           # Main analysis runner
├── mix/
│   └── tasks/
│       ├── code.audit.ex   # Main Mix task definition
│       └── code.audit.init.ex # Config generation task
└── code_audit.ex           # Package entrypoint
```
