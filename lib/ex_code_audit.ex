defmodule ExCodeAudit do
  @moduledoc """
  ExCodeAudit is a tool to audit Phoenix projects for coding standards adherence.

  It provides a mix task to scan your codebase for violations of your organization's
  coding standards, with various analyzers and configurable rule sets.

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
  """

  @doc """
  Hello world.

  ## Examples

      iex> ExCodeAudit.hello()
      :world

  """
  def hello do
    :world
  end
end
