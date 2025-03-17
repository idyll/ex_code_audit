defmodule ExCodeAudit.Rules do
  @moduledoc """
  A module to manage and access all available rules.

  This module provides functions to list all rules, filter enabled rules,
  and find rules by name.
  """

  @doc """
  Returns a list of all available rule modules.

  ## Returns

  A list of module names that implement the ExCodeAudit.Rule behavior

  ## Examples

      iex> ExCodeAudit.Rules.all()
      [ExCodeAudit.Analyzers.FileSize, ExCodeAudit.Analyzers.Schema, ExCodeAudit.Analyzers.LiveView, ExCodeAudit.Analyzers.RepoCalls, ExCodeAudit.Analyzers.TestCoverage, ExCodeAudit.Analyzers.Factory]
  """
  @spec all() :: [module()]
  def all do
    [
      ExCodeAudit.Analyzers.FileSize,
      ExCodeAudit.Analyzers.Schema,
      ExCodeAudit.Analyzers.LiveView,
      ExCodeAudit.Analyzers.RepoCalls,
      ExCodeAudit.Analyzers.TestCoverage,
      ExCodeAudit.Analyzers.Factory
    ]
  end

  @doc """
  Filters rules based on the configuration.

  Returns only rules that are enabled in the given configuration.

  ## Parameters

  - `config`: The configuration map

  ## Returns

  A list of enabled rule modules

  ## Examples

      iex> config = ExCodeAudit.Config.load()
      iex> ExCodeAudit.Rules.enabled(config)
      [ExCodeAudit.Analyzers.FileSize, ExCodeAudit.Analyzers.Schema, ExCodeAudit.Analyzers.LiveView, ExCodeAudit.Analyzers.RepoCalls, ExCodeAudit.Analyzers.TestCoverage, ExCodeAudit.Analyzers.Factory]
  """
  @spec enabled(map()) :: [module()]
  def enabled(config) do
    all()
    |> Enum.filter(fn rule ->
      rule_name = rule.name()
      ExCodeAudit.Config.rule_enabled?(config, rule_name)
    end)
  end

  @doc """
  Finds a rule module by its name.

  ## Parameters

  - `rule_name`: The name of the rule to find

  ## Returns

  The rule module if found, nil otherwise

  ## Examples

      iex> ExCodeAudit.Rules.find_by_name(:file_size)
      ExCodeAudit.Analyzers.FileSize

      iex> ExCodeAudit.Rules.find_by_name(:schema_location)
      ExCodeAudit.Analyzers.Schema

      iex> ExCodeAudit.Rules.find_by_name(:live_view_sections)
      ExCodeAudit.Analyzers.LiveView

      iex> ExCodeAudit.Rules.find_by_name(:repo_calls)
      ExCodeAudit.Analyzers.RepoCalls

      iex> ExCodeAudit.Rules.find_by_name(:test_coverage)
      ExCodeAudit.Analyzers.TestCoverage

      iex> ExCodeAudit.Rules.find_by_name(:fixture_usage)
      ExCodeAudit.Analyzers.Factory
  """
  @spec find_by_name(atom()) :: module() | nil
  def find_by_name(rule_name) do
    Enum.find(all(), fn rule -> rule.name() == rule_name end)
  end
end
