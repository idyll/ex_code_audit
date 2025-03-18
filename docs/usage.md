# ExCodeAudit Usage Guide

This guide covers how to use the ExCodeAudit tool effectively for your Elixir projects.

## Basic Usage

To run the code audit with default settings:

```bash
mix code.audit
```

This will scan your codebase for violations of the configured rules and output the results to the console.

## Command-Line Options

The following command-line options are available:

| Option | Description |
|--------|-------------|
| `--strict` | Exit with a non-zero code if any errors are found (useful for CI) |
| `--format=<format>` | Output format, either "console" (default) or "json" |
| `--output=<file>` | Write the output to a file instead of stdout |
| `--verbose` | Show more detailed information about violations |
| `--only=<rule1,rule2>` | Only run specific rules (comma-separated list) |
| `--skip-compile` | Skip checking for compiler warnings |
| `--with-coverage` | Check test coverage against the configured minimum percentage |
| `--fix` | Auto-fix certain issues (currently supports LiveView section labels) |
| `--preview` | Preview fixes without applying them (use with `--fix`) |
| `--force` | Force recreation of headers even if they exist (use with `--fix`) |

## Usage Examples

### Running in CI Environments

For CI environments, you'll typically want to run in strict mode:

```bash
mix code.audit --strict
```

This ensures that any rule violations categorized as errors will cause a non-zero exit code, which will fail the CI job.

### Checking Only Specific Rules

You can focus on specific rules if you're working on addressing particular issues:

```bash
# Check only schema location and repo call rules
mix code.audit --only=schema_location,repo_calls
```

### JSON Output for Tooling Integration

You can output the results in JSON format for integration with other tools:

```bash
mix code.audit --format=json --output=audit_results.json
```

### Checking Test Coverage

To include test coverage validation in your audit:

```bash
mix code.audit --with-coverage
```

This requires that you've run your tests with coverage enabled (`mix test --cover`).

## Auto-Fix Features

ExCodeAudit includes the ability to automatically fix certain issues it detects. Currently, the tool supports:

### LiveView Section Labels

The tool can automatically add missing LiveView section labels:

```bash
# Auto-fix LiveView section issues
mix code.audit --fix
```

This will analyze your LiveView files and add any missing section labels according to your configuration.

### Previewing Auto-Fixes

To see what changes would be made without actually applying them:

```bash
mix code.audit --fix --preview
```

When using the `--preview` option, the tool will display:

1. The files with issues
2. A diff-style preview of the changes that will be made
3. The exact line numbers where changes will be applied
4. File paths with line numbers for easy navigation

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

### Forcing Section Recreation

If you want to recreate section headers even if they already exist (for example, to update their formatting):

```bash
mix code.audit --fix --force
```

## Incorporating Into Your Workflow

### Pre-commit Hooks

You can add ExCodeAudit to your pre-commit hooks to ensure code quality before committing changes. For example, with the `pre-commit` tool:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: code-audit
      name: Elixir Code Audit
      entry: mix code.audit
      language: system
      pass_filenames: false
```

### Editor Integration

You can integrate ExCodeAudit with your editor's task system. For example, in VS Code:

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Code Audit",
      "type": "shell",
      "command": "mix code.audit",
      "problemMatcher": [],
      "group": {
        "kind": "test",
        "isDefault": true
      }
    }
  ]
}
```

### Custom Mix Aliases

For convenience, you can define custom mix aliases in your `mix.exs` file:

```elixir
defp aliases do
  [
    # ...
    audit: ["code.audit"],
    "audit.fix": ["code.audit --fix"],
    "audit.preview": ["code.audit --fix --preview"],
    # ...
  ]
end
```

Then you can use shorter commands:

```bash
mix audit
mix audit.fix
mix audit.preview
```

## Next Steps

After running the audit, you'll get a list of violations to address. You can:

1. Fix the violations manually based on the guidance provided
2. Use the auto-fix features for supported issues
3. Review your configuration if you need to adjust the rules for your project

For more information on configuration options, see [Configuration Guide](configuration.md).
For details on specific rules, see [Rule Descriptions](rules/index.md).
