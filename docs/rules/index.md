# ExCodeAudit Rules

This section documents all the rules available in ExCodeAudit.

## Available Rules

ExCodeAudit includes the following analyzers:

| Rule | Description | Auto-Fix Support |
|------|-------------|------------------|
| [File Size](file_size.md) | Checks file sizes against configured limits | No |
| [Schema Location](schema_location.md) | Verifies that schema files are in the proper location | No |
| [Schema Content](schema_content.md) | Checks what schema files contain | No |
| [LiveView Sections](live_view_sections.md) | Checks for proper section labels in LiveView modules | Yes |
| [Repository Calls](repo_calls.md) | Checks for repository calls in inappropriate modules | No |
| [Test Coverage](test_coverage.md) | Verifies test coverage levels | No |
| [Factory Usage](fixture_usage.md) | Checks for proper factory usage in tests | No |

## Rule Categories

### Code Organization

- [Schema Location](schema_location.md) - Ensures schemas are properly organized
- [Repository Calls](repo_calls.md) - Controls where database operations are performed

### Code Structure

- [LiveView Sections](live_view_sections.md) - Enforces consistent LiveView organization
- [File Size](file_size.md) - Prevents files from becoming too large

### Testing & Quality

- [Test Coverage](test_coverage.md) - Maintains testing standards
- [Factory Usage](fixture_usage.md) - Encourages proper test data generation

## Configuring Rules

Each rule can be configured individually. Common configuration options include:

- `enabled` - Enable or disable the rule
- `violation_level` - Set to `warning` or `error` to control severity

For detailed configuration options for each rule, see the individual rule documentation.

## Auto-Fix Support

Currently, only the [LiveView Sections](live_view_sections.md) rule supports auto-fixing. When enabled with `mix code.audit --fix`, the tool will automatically add missing section headers to LiveView files.

## Creating Custom Rules

*Note: This is a planned feature and may not be available in the current version.*

In the future, ExCodeAudit will support custom rules through a plugin system. This will allow you to create your own rules to enforce project-specific conventions.

## Rule Best Practices

1. **Start simple**: Begin with a small set of rules on a new project and gradually increase as the team adapts
2. **Set appropriate severity levels**: Use `warning` for guidelines and `error` for critical issues
3. **Document special cases**: If you customize rules for your project, document the reasons and expectations
4. **Follow the principle of least surprise**: Configure rules to match team expectations and coding style
