# LiveView Section Auto-Fix Feature

## Overview

We've implemented an auto-fix feature for the LiveView section analyzer that automatically adds missing section labels to LiveView modules. This feature helps developers maintain consistent code structure without manual intervention.

## Features Implemented

1. **Automatic Section Detection**: Analyzes LiveView files and categorizes functions into different types (lifecycle callbacks, event handlers, and rendering functions).

2. **Intelligent Section Placement**: Inserts section labels in the appropriate places in the code, right before the first function of each type.

3. **Preview Mode**: The `--preview` flag allows users to see what changes would be made without actually modifying any files.

4. **Force Option**: The `--force` flag allows users to recreate section labels even if they already exist, useful for standardizing format.

5. **Smart Handling of Existing Sections**: Avoids duplicating section labels that already exist in the file.

## Command-Line Interface

Added the following options to the mix task:

```bash
# To fix all LiveView missing section issues
mix code.audit --fix

# To preview fixes without applying them
mix code.audit --fix --preview

# To force recreation of section labels even if they already exist
mix code.audit --fix --force
```

## Implementation Details

1. **LiveView Fixer Module**: Created `ExCodeAudit.Fixers.LiveView` module to handle the actual fixes.

2. **Mix Task Integration**: Updated the `Mix.Tasks.Code.Audit` module to support the new options.

3. **Documentation**: Added documentation to the README and module docs.

4. **Comprehensive Tests**: Added tests for all aspects of the new functionality.

## Usage Example

When a user runs `mix code.audit --fix`, the tool:

1. Scans the codebase for LiveView files missing required section labels
2. For each file with violations:
   - Reads the file content
   - Analyzes the function structure
   - Adds missing section labels in appropriate locations
   - Writes the updated content back to the file
3. Reports the number of files fixed

The preview mode (`--fix --preview`) shows exactly what changes would be made without applying them.

## Future Enhancements

1. **Enhance Section Detection**: Could add more function patterns for better categorization
2. **Format Standardization**: Could standardize the format of existing section labels
3. **Additional Auto-Fixes**: Could extend the approach to fix other types of violations

## Status

- ✅ Feature is fully implemented and tested
- ✅ Documentation has been updated
- ✅ All tests pass successfully
