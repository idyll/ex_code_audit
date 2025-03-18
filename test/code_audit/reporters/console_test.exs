defmodule ExCodeAudit.Reporters.ConsoleTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias ExCodeAudit.{Violation, Reporters.Console}

  describe "report/2" do
    test "handles map options instead of keyword list" do
      violation =
        Violation.new(
          "Test message",
          "test/file.ex",
          level: :warning,
          rule: :test_rule
        )

      # Using a map instead of keyword list for options
      options = %{verbose: true, format: "console"}

      output =
        capture_io(fn ->
          Console.report([violation], options)
        end)

      # Updated assertions to match the new format
      assert String.contains?(output, "warning:")
      assert String.contains?(output, "Test message")
      assert String.contains?(output, "└─ test/file.ex")  # New location format
      assert String.contains?(output, "Rule: test_rule")
    end

    test "handles keyword list options" do
      violation =
        Violation.new(
          "Test message",
          "test/file.ex",
          level: :error,
          rule: :test_rule
        )

      # Using a keyword list for options
      options = [verbose: true]

      output =
        capture_io(fn ->
          Console.report([violation], options)
        end)

      # Updated assertions to match the new format
      assert String.contains?(output, "error:")
      assert String.contains?(output, "Test message")
      assert String.contains?(output, "└─ test/file.ex")  # New location format
      assert String.contains?(output, "Rule: test_rule")
    end
  end
end
