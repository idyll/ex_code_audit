defmodule ExCodeAudit.Rule do
  @moduledoc """
  A behavior defining the interface for code audit rules.

  All rule modules should implement this behavior to ensure they provide
  the necessary functions for the rule runner to execute them.
  """

  alias ExCodeAudit.Violation

  @doc """
  Returns the name of the rule, which is used for configuration and reporting.
  """
  @callback name() :: atom()

  @doc """
  Returns a human-readable description of the rule.
  """
  @callback description() :: String.t()

  @doc """
  Applies the rule to a file and returns any violations found.

  ## Parameters

  - `file_path`: The path to the file being analyzed
  - `file_content`: The content of the file as a string
  - `config`: The configuration map for this rule

  ## Returns

  A list of violation structs or an empty list if no violations were found
  """
  @callback check(String.t(), String.t(), map()) :: [Violation.t()]

  @doc """
  Runs a check on a single file and returns any violations found.

  This function is called by the rule runner for each file that should be
  checked by this rule.

  ## Parameters

  - `module`: The module implementing the Rule behavior
  - `file_path`: The path to the file being analyzed
  - `config`: The configuration map for this rule

  ## Returns

  A list of violation structs or an empty list if no violations were found
  """
  @spec check_file(module(), String.t(), map()) :: [Violation.t()]
  def check_file(module, file_path, config) do
    with {:ok, content} <- File.read(file_path) do
      module.check(file_path, content, config)
    else
      {:error, _reason} -> []
    end
  end

  @doc """
  A macro to use at the beginning of rule modules to implement the Rule behavior.

  ## Examples

      defmodule MyRule do
        use ExCodeAudit.Rule

        def name, do: :my_rule
        def description, do: "My custom rule description"

        def check(file_path, file_content, config) do
          # Rule implementation
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour ExCodeAudit.Rule
      import ExCodeAudit.Rule
    end
  end
end
