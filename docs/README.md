# ExCodeAudit Documentation

Welcome to the ExCodeAudit documentation. This documentation provides comprehensive information about the ExCodeAudit tool, its features, and how to use it effectively.

## Table of Contents

- [Usage Guide](usage.md) - How to use ExCodeAudit effectively
- [Configuration Guide](configuration.md) - How to configure ExCodeAudit
- [Rule Descriptions](rules/index.md) - Detailed documentation for each rule

## Key Documentation Pages

### Usage

- [Basic Usage](usage.md#basic-usage)
- [Command-Line Options](usage.md#command-line-options)
- [Auto-Fix Features](usage.md#auto-fix-features)
- [Workflow Integration](usage.md#incorporating-into-your-workflow)

### Configuration

- [Configuration Methods](configuration.md#configuration-methods)
- [File Formats](configuration.md#configuration-file-formats)
- [Common Options](configuration.md#common-configuration-options)
- [Best Practices](configuration.md#configuration-best-practices)

### Rules

- [LiveView Sections](rules/live_view_sections.md) - Enforce consistent LiveView organization
- [Repository Calls](rules/repo_calls.md) - Control where database operations are performed
- [Schema Location](rules/schema_location.md) - Ensure schemas are properly organized
- [File Size](rules/file_size.md) - Prevent files from becoming too large
- [Test Coverage](rules/test_coverage.md) - Maintain testing standards
- [Factory Usage](rules/fixture_usage.md) - Encourage proper test data generation

## Quick Start

To start using ExCodeAudit:

1. Add to your dependencies:

```elixir
def deps do
  [
    {:ex_code_audit, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

2. Run the basic audit:

```bash
mix code.audit
```

3. Generate a configuration file:

```bash
mix code.audit.init
```

4. Edit the generated `.code_audit.yml` file to customize rules for your project.

5. Run the audit with your custom configuration:

```bash
mix code.audit
```

For more detailed information, see the [Usage Guide](usage.md).
