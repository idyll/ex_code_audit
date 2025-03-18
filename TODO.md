## TODO

### Phase 1: Setup and Core Infrastructure

- [x] Create new Mix project with proper dependencies
- [x] Set up the project structure
- [x] Define the core configuration system
- [x] Create violation tracking system
- [x] Implement basic Mix task
- [x] Set up testing framework

#### Technical Details

- [x] Use `nimble_parsec` for file parsing
- [x] Use `file_system` for efficient file traversal
- [x] Define a `Rule` behavior for all rules to implement

### Phase 2: Basic Analyzers

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

- [x] Use pattern matching to identify file types
- [x] Implement efficient file traversal that skips directories like `_build` and `deps`
- [x] Create clear violation messages with file locations

### Phase 3: Code Content Analysis

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

- [ ] Use the Elixir `Code` module to parse and analyze AST
- [x] Create pattern matchers for common Elixir constructs
- [ ] Implement efficient caching to avoid re-analyzing files

### Phase 4: Testing Analysis ✅

- [x] Implement test coverage analyzer
  - [x] Check test file existence for modules
  - [x] Integrate with existing coverage tools
- [x] Implement factory usage checker
  - [x] Detect fixtures vs factories
  - [x] Verify factory naming

#### Technical Details

- [x] Parse existing coverage reports
- [x] Integrate with `excoveralls` if available
- [x] Scan for fixture patterns in test files

### Phase 5: Configuration and Customization

- [x] Implement configuration file system
  - [x] Allow YAML configuration files
  - [x] Allow JSON configuration files
  - [x] Support global and project-specific overrides
- [x] Create config generation tool
  - [x] Generate sample YAML config
  - [x] Generate sample JSON config
- [ ] Implement custom rule definitions
  - [ ] Allow user-defined rules
  - [ ] Support custom matchers

#### Technical Details

- [x] Use YAML or JSON for configuration
- [x] Support both global and project-level configs
- [x] Implement inheritance and overriding

### Phase 6: CI Integration and Polish

- [ ] Add GitHub Actions integration
  - [ ] Output in GitHub annotation format
- [x] Implement strict mode
  - [x] Return proper exit codes
  - [x] Allow severity level configuration
- [x] Add compiler warnings integration
  - [x] Run compiler with --warnings-as-errors
  - [x] Include warnings in audit results
- [x] Implement auto-fix capability
  - [x] Add `--fix` option to automatically repair issues
  - [x] Fix missing LiveView section labels
  - [x] Add `--preview` flag to show changes without applying them
  - [x] Add `--force` flag to recreate headers even if they exist
- [x] Add comprehensive documentation
  - [x] Usage examples
  - [x] Configuration options
  - [x] Rule descriptions

#### Technical Details

- [ ] Follow GitHub Actions annotation format
- [x] Create proper exit codes based on violation severity
- [x] Generate complete documentation

### Phase 7: Testing and Release

- [ ] Comprehensive test suite
  - [x] Unit tests for all analyzers
  - [ ] Integration tests with sample projects
- [ ] Performance optimization
  - [ ] Improve file traversal speed
  - [ ] Implement caching
- [ ] Publish to Hex.pm
  - [ ] Package documentation
  - [ ] Version strategy
