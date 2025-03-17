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

Documentation is available at [https://hexdocs.pm/ex_code_audit](https://hexdocs.pm/ex_code_audit).

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

## Development Process

### Phase 1: Setup and Core Infrastructure (2-3 days)

- [x] Create new Mix project with proper dependencies
- [x] Set up the project structure
- [x] Define the core configuration system
- [x] Create violation tracking system
- [x] Implement basic Mix task
- [x] Set up testing framework

#### Technical Details

- Use `nimble_parsec` for file parsing
- Use `file_system` for efficient file traversal
- Define a `Rule` behavior for all rules to implement

### Phase 2: Basic Analyzers (3-4 days)

- [x] Implement file structure analyzer
  - [x] Directory structure validation
  - [x] File naming convention checking
- [x] Implement file size analyzer
  - [x] Line count tracking
  - [x] File size warnings
- [x] Implement basic reporters
  - [x] Console reporter with color coding
  - [x] JSON reporter for machine consumption

#### Technical Details

- Use pattern matching to identify file types
- Implement efficient file traversal that skips directories like `_build` and `deps`
- Create clear violation messages with file locations

### Phase 3: Code Content Analysis (4-5 days)

- [x] Implement schema analyzer
  - [x] Detect schema definitions
  - [x] Verify schema placement
  - [x] Check for Repo calls in schema files
- [x] Implement LiveView analyzer
  - [x] Detect section labels
  - [x] Check for external templates
  - [x] Verify component structure
- [x] Implement repository call analyzer
  - [x] Detect Repo calls
  - [x] Verify they're in the correct modules

#### Technical Details

- Use the Elixir `Code` module to parse and analyze AST
- Create pattern matchers for common Elixir constructs
- Implement efficient caching to avoid re-analyzing files

### Phase 4: Testing Analysis (2-3 days)

- [x] Implement test coverage analyzer
  - [x] Check test file existence for modules
  - [x] Integrate with existing coverage tools
- [x] Implement factory usage checker
  - [x] Detect fixtures vs factories
  - [x] Verify factory naming

#### Technical Details

- Parse existing coverage reports
- Integrate with `excoveralls` if available
- Scan for fixture patterns in test files

### Phase 5: Configuration and Customization (2-3 days)

- [x] Implement configuration file system
  - [x] Allow YAML configuration files
  - [x] Allow JSON configuration files
  - [x] Support global and project-specific config files
- [ ] Create rule customization system
  - [ ] Allow rule disabling
  - [ ] Support custom thresholds

#### Technical Details

- Use YAML or JSON for configuration
- Support both global and project-level configs
- Implement inheritance and overriding

### Phase 6: CI Integration and Polish (3-4 days)

- [ ] Add GitHub Actions integration
  - [ ] Output in GitHub annotation format
- [ ] Implement strict mode
  - [ ] Return proper exit codes
  - [ ] Allow severity level configuration
- [ ] Add comprehensive documentation
  - [ ] Usage examples
  - [ ] Configuration options
  - [ ] Rule descriptions

#### Technical Details

- Follow GitHub Actions annotation format
- Create proper exit codes based on violation severity
- Generate complete HexDocs

### Phase 7: Testing and Release (2-3 days)

- [ ] Comprehensive test suite
  - [ ] Unit tests for all analyzers
  - [ ] Integration tests with sample projects
- [ ] Performance optimization
  - [ ] Improve file traversal speed
  - [ ] Implement caching
- [ ] Publish to Hex.pm
  - [ ] Package documentation
  - [ ] Version strategy

## Implementation Details

### Configuration Example

```elixir
# In config/config.exs
config :elixir_code_audit,
  rules: [
    # Schema rules
    schema_location: [
      path: "lib/:app_name/schemas/*.ex",
      violation_level: :error
    ],
    schema_content: [
      excludes: ["Repo."],
      violation_level: :warning
    ],
    
    # LiveView rules
    live_view_sections: [
      required: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"],
      violation_level: :warning
    ],
    
    # File size rules
    file_size: [
      max_lines: 1000,
      warning_at: 920,
      violation_level: :warning
    ],
    
    # Testing rules
    test_coverage: [
      min_percentage: 90,
      violation_level: :error
    ],
    fixture_usage: [
      allowed: false,
      violation_level: :error
    ]
  ],
  
  # Paths to exclude from analysis
  excluded_paths: [
    "deps/**",
    "_build/**",
    "priv/static/**"
  ]
```

### Example Mix Task Usage

```bash
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
```

### Example Output

```
ElixirCodeAudit v0.1.0

Scanning project...

❌ ERROR: Schema file found in incorrect location
   File: lib/my_app/user.ex
   Expected location: lib/my_app/schemas/user.ex

⚠️ WARNING: File exceeds recommended size limit
   File: lib/my_app_web/live/dashboard_live/index.ex
   Current size: 1243 lines
   Recommended max: 1000 lines

⚠️ WARNING: LiveView missing labeled sections
   File: lib/my_app_web/live/user_live/show.ex
   Missing sections: ["INFO HANDLERS"]

⚠️ WARNING: Repo call found outside schema operation module
   File: lib/my_app/user.ex:45
   Repo calls should be in lib/my_app/user/creator.ex or similar

❌ ERROR: No factory found for test data generation
   Expected: test/support/factory.ex

Summary:
  2 errors
  3 warnings
  78 files analyzed
  
Run with --details for more information on each violation.
```

## Technology Stack

- **Elixir**: Core language
- **Mix**: Build tool and task runner
- **nimble_parsec**: For efficient text parsing
- **file_system**: For file watching capabilities
- **yaml_elixir**: For configuration file parsing
- **ex_doc**: For documentation generation
- **excoveralls**: For coverage integration

## Timeline

- **Phase 1-2**: 5-7 days
- **Phase 3-4**: 6-8 days
- **Phase 5-6**: 5-7 days
- **Phase 7**: 2-3 days
- **Total**: 18-25 days

## Future Enhancements

- **Auto-fix mode**: Automatically correct simple violations
- **Editor integration**: VSCode and other editor plugins
- **Custom rule creation**: API for creating custom rules
- **Project templates**: Generate compliant project templates
- **Migration assistant**: Help migrate existing projects
- **Dashboard**: Web UI for visualizing compliance over time

## Success Metrics

1. Successfully detects all violations of the code organization rules
2. Performance suitable for CI environments (under 30 seconds for medium projects)
3. Clear, actionable output that guides developers to fix issues
4. Configurable to match specific project requirements
5. Easy integration with existing workflows and CI pipelines

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| False positives | Extensive testing with real projects, configurable thresholds |
| Performance issues | Implement efficient file traversal, caching, incremental analysis |
| AST analysis complexity | Start with simpler pattern matching, gradually add AST analysis |
| Configuration complexity | Well-documented defaults, validation of config options |
| Tool adoption resistance | Make the tool helpful rather than punitive, provide clear explanations |
