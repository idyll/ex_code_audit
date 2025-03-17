defmodule ExCodeAudit.TestWarnings do
  @moduledoc """
  This module is just for testing compiler warnings detection.
  """

  @doc """
  A function with an unused variable to trigger a warning.
  """
  def test_function do
    _unused_var = "This variable is not used"

    "No warnings here"
  end
end
