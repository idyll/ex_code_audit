defmodule ExCodeAudit.Analyzers.TestCoverageTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.TestCoverage

  describe "name/0" do
    test "returns the correct rule name" do
      assert TestCoverage.name() == :test_coverage
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert TestCoverage.description() != ""
      assert is_binary(TestCoverage.description())
    end
  end

  describe "check/3" do
    setup do
      # Create a temporary test file structure
      tmp_dir = System.tmp_dir()
      lib_dir = Path.join(tmp_dir, "lib/my_app")
      test_dir = Path.join(tmp_dir, "test/my_app")

      File.mkdir_p!(lib_dir)
      File.mkdir_p!(test_dir)

      # Create a module file with a test
      module_path = Path.join(lib_dir, "user.ex")
      test_path = Path.join(test_dir, "user_test.exs")

      File.write!(module_path, """
      defmodule MyApp.User do
        def hello, do: "world"
      end
      """)

      File.write!(test_path, """
      defmodule MyApp.UserTest do
        use ExUnit.Case

        test "hello returns world" do
          assert MyApp.User.hello() == "world"
        end
      end
      """)

      # Create a module file without a test
      no_test_module_path = Path.join(lib_dir, "account.ex")

      File.write!(no_test_module_path, """
      defmodule MyApp.Account do
        def balance, do: 100
      end
      """)

      on_exit(fn ->
        # Clean up the files after tests
        File.rm(module_path)
        File.rm(test_path)
        File.rm(no_test_module_path)
      end)

      # Return paths for use in tests
      %{
        module_path: module_path,
        test_path: test_path,
        no_test_module_path: no_test_module_path,
        tmp_dir: tmp_dir
      }
    end

    test "detects missing test files", %{no_test_module_path: no_test_module_path} do
      config = %{
        check_test_existence: true,
        violation_level: :warning
      }

      content = File.read!(no_test_module_path)

      violations = TestCoverage.check(no_test_module_path, content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :test_coverage
      assert violation.file == no_test_module_path
      assert String.contains?(violation.message, "Missing test file for module")
    end

    test "accepts files with existing test files", %{module_path: module_path} do
      config = %{
        check_test_existence: true,
        violation_level: :warning
      }

      content = File.read!(module_path)

      # This should not produce violations since the test file exists
      violations = TestCoverage.check(module_path, content, config)
      assert violations == []
    end

    test "detects low test coverage", %{no_test_module_path: no_test_module_path} do
      # Create mock coverage data
      coverage_data = %{
        Path.expand(no_test_module_path) => %{
          # Line 1 covered once
          1 => 1,
          # Line 2 not covered
          2 => 0,
          # Line 3 not covered
          3 => 0
        }
      }

      config = %{
        min_percentage: 80,
        coverage_data: coverage_data,
        violation_level: :error
      }

      content = File.read!(no_test_module_path)

      violations = TestCoverage.check(no_test_module_path, content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :error
      assert violation.rule == :test_coverage
      assert violation.file == no_test_module_path
      assert String.contains?(violation.message, "Test coverage below minimum threshold")
      # 33% coverage (1 of 3 lines)
      assert String.contains?(violation.message, "33")
    end

    test "accepts files with good test coverage", %{module_path: module_path} do
      # Create mock coverage data with good coverage
      coverage_data = %{
        Path.expand(module_path) => %{
          # Line 1 covered once
          1 => 1,
          # Line 2 covered twice
          2 => 2,
          # Line 3 covered once
          3 => 1
        }
      }

      config = %{
        check_test_existence: true,
        min_percentage: 80,
        coverage_data: coverage_data,
        violation_level: :error
      }

      content = File.read!(module_path)

      # This should not produce violations since coverage is good
      violations = TestCoverage.check(module_path, content, config)
      assert violations == []
    end

    test "ignores test files", %{test_path: test_path} do
      config = %{
        check_test_existence: true,
        violation_level: :warning
      }

      content = File.read!(test_path)

      # This should not produce violations since we're checking a test file
      violations = TestCoverage.check(test_path, content, config)
      assert violations == []
    end

    test "allows disabling test existence check", %{no_test_module_path: no_test_module_path} do
      config = %{
        check_test_existence: false,
        violation_level: :warning
      }

      content = File.read!(no_test_module_path)

      # This should not produce violations since test existence check is disabled
      violations = TestCoverage.check(no_test_module_path, content, config)
      assert violations == []
    end
  end
end
