defmodule ExCodeAudit.Violation do
  @moduledoc """
  A struct representing a violation found during code auditing.

  This module defines a violation structure and functions to create and manipulate
  violations.
  """

  @type level :: :warning | :error

  @type t :: %__MODULE__{
          message: String.t(),
          file: String.t(),
          line: non_neg_integer() | nil,
          level: level(),
          rule: atom()
        }

  defstruct [
    :message,
    :file,
    :line,
    :level,
    :rule
  ]

  @doc """
  Creates a new violation with the given attributes.

  ## Parameters

  - `message`: A description of the violation
  - `file`: The file where the violation occurred
  - `opts`: Additional options
    - `:line`: The line number where the violation occurred (optional)
    - `:level`: The severity level of the violation (:warning or :error)
    - `:rule`: The rule that was violated

  ## Examples

      iex> ExCodeAudit.Violation.new("Schema file in wrong directory", "lib/app/user.ex", level: :error, rule: :schema_location)
      %ExCodeAudit.Violation{
        message: "Schema file in wrong directory",
        file: "lib/app/user.ex",
        level: :error,
        rule: :schema_location
      }

  """
  @spec new(String.t(), String.t(), Keyword.t()) :: t()
  def new(message, file, opts \\ []) do
    %__MODULE__{
      message: message,
      file: file,
      line: Keyword.get(opts, :line),
      level: Keyword.get(opts, :level, :warning),
      rule: Keyword.get(opts, :rule)
    }
  end

  @doc """
  Determines if a violation is an error.

  ## Examples

      iex> violation = ExCodeAudit.Violation.new("message", "file.ex", level: :error)
      iex> ExCodeAudit.Violation.error?(violation)
      true

      iex> violation = ExCodeAudit.Violation.new("message", "file.ex", level: :warning)
      iex> ExCodeAudit.Violation.error?(violation)
      false

  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{level: :error}), do: true
  def error?(%__MODULE__{}), do: false
end
