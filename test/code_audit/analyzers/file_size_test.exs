defmodule ExCodeAudit.Analyzers.FileSizeTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.FileSize

  describe "name/0" do
    test "returns the correct rule name" do
      assert FileSize.name() == :file_size
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert FileSize.description() != ""
      assert is_binary(FileSize.description())
    end
  end

  describe "check/3" do
    test "returns no violations for small files" do
      content = """
      defmodule Test do
        def hello do
          :world
        end
      end
      """

      config = %{
        max_lines: 1000,
        warning_at: 800,
        violation_level: :warning
      }

      assert FileSize.check("test.ex", content, config) == []
    end

    test "returns warning for files approaching max size" do
      # Generate a file with more lines than the warning threshold
      lines = Enum.map(1..850, fn i -> "line #{i}" end)
      content = Enum.join(lines, "\n")

      config = %{
        max_lines: 1000,
        warning_at: 800,
        violation_level: :warning
      }

      violations = FileSize.check("large_file.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :file_size
      assert violation.file == "large_file.ex"
      assert String.contains?(violation.message, "approaches maximum size limit")
    end

    test "returns error for files exceeding max size" do
      # Generate a file with more lines than the max threshold
      lines = Enum.map(1..1050, fn i -> "line #{i}" end)
      content = Enum.join(lines, "\n")

      config = %{
        max_lines: 1000,
        warning_at: 800,
        violation_level: :error
      }

      violations = FileSize.check("very_large_file.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :error
      assert violation.rule == :file_size
      assert violation.file == "very_large_file.ex"
      assert String.contains?(violation.message, "exceeds maximum size limit")
    end

    test "skips non-Elixir files" do
      # Generate a large file
      lines = Enum.map(1..1500, fn i -> "line #{i}" end)
      content = Enum.join(lines, "\n")

      config = %{
        max_lines: 1000,
        warning_at: 800,
        violation_level: :error
      }

      # Test with a non-Elixir file
      assert FileSize.check("large_file.txt", content, config) == []
    end
  end
end
