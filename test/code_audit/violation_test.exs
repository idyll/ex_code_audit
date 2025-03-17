defmodule ExCodeAudit.ViolationTest do
  use ExUnit.Case, async: true
  doctest ExCodeAudit.Violation

  alias ExCodeAudit.Violation

  describe "new/3" do
    test "creates a new violation with default options" do
      violation = Violation.new("test message", "file.ex")

      assert violation.message == "test message"
      assert violation.file == "file.ex"
      assert violation.level == :warning
      assert violation.line == nil
      assert violation.rule == nil
    end

    test "creates a new violation with provided options" do
      violation =
        Violation.new("test message", "file.ex",
          level: :error,
          line: 42,
          rule: :test_rule
        )

      assert violation.message == "test message"
      assert violation.file == "file.ex"
      assert violation.level == :error
      assert violation.line == 42
      assert violation.rule == :test_rule
    end
  end

  describe "error?/1" do
    test "returns true for error violations" do
      violation = Violation.new("test message", "file.ex", level: :error)
      assert Violation.error?(violation) == true
    end

    test "returns false for warning violations" do
      violation = Violation.new("test message", "file.ex", level: :warning)
      assert Violation.error?(violation) == false
    end
  end
end
