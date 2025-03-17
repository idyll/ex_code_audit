defmodule ExCodeAudit.Analyzers.FactoryTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.Factory

  describe "name/0" do
    test "returns the correct rule name" do
      assert Factory.name() == :fixture_usage
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert Factory.description() != ""
      assert is_binary(Factory.description())
    end
  end

  describe "check/3" do
    setup do
      # Create a temporary test structure
      tmp_dir = System.tmp_dir()
      test_dir = Path.join(tmp_dir, "test")
      support_dir = Path.join(test_dir, "support")

      File.mkdir_p!(test_dir)
      File.mkdir_p!(support_dir)

      # Test file with fixtures
      test_with_fixtures_path = Path.join(test_dir, "user_test.exs")

      File.write!(test_with_fixtures_path, """
      defmodule MyApp.UserTest do
        use ExUnit.Case

        setup do
          fixtures = %{name: "John", email: "john@example.com"}
          {:ok, fixtures}
        end

        test "user attributes", %{name: name} do
          assert name == "John"
        end
      end
      """)

      # Test file without fixtures
      clean_test_path = Path.join(test_dir, "account_test.exs")

      File.write!(clean_test_path, """
      defmodule MyApp.AccountTest do
        use ExUnit.Case

        test "account balance" do
          assert MyApp.Account.balance() == 100
        end
      end
      """)

      # Create a factory file
      factory_path = Path.join(support_dir, "factory.ex")

      File.write!(factory_path, """
      defmodule MyApp.Factory do
        use ExMachina

        def user_factory do
          %MyApp.User{
            name: "Jane",
            email: "jane@example.com"
          }
        end
      end
      """)

      on_exit(fn ->
        # Clean up the files after tests
        File.rm(test_with_fixtures_path)
        File.rm(clean_test_path)
        File.rm(factory_path)
      end)

      # Return paths for use in tests
      %{
        test_with_fixtures_path: test_with_fixtures_path,
        clean_test_path: clean_test_path,
        factory_path: factory_path,
        tmp_dir: tmp_dir
      }
    end

    test "detects fixture usage in test files", %{
      test_with_fixtures_path: test_with_fixtures_path
    } do
      config = %{
        allowed: false,
        violation_level: :warning
      }

      content = File.read!(test_with_fixtures_path)

      violations = Factory.check(test_with_fixtures_path, content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :fixture_usage
      assert violation.file == test_with_fixtures_path
      assert String.contains?(violation.message, "Test uses fixtures instead of factories")
    end

    test "allows fixtures if configured", %{test_with_fixtures_path: test_with_fixtures_path} do
      config = %{
        allowed: true,
        violation_level: :warning
      }

      content = File.read!(test_with_fixtures_path)

      violations = Factory.check(test_with_fixtures_path, content, config)

      assert violations == []
    end

    test "accepts test files without fixtures", %{clean_test_path: clean_test_path} do
      config = %{
        allowed: false,
        violation_level: :warning
      }

      content = File.read!(clean_test_path)

      violations = Factory.check(clean_test_path, content, config)

      assert violations == []
    end

    test "validates factory existence when requested", %{factory_path: factory_path} do
      # Temporarily move factory file to simulate missing factory
      temp_path = "#{factory_path}.bak"
      File.rename!(factory_path, temp_path)

      try do
        config = %{
          allowed: false,
          check_factory_exists: true,
          violation_level: :error
        }

        # Check with a test file to trigger factory check
        content = "defmodule SomeTest do\n  use ExUnit.Case\nend"
        non_test_path = "/some/non/test/file.ex"

        violations = Factory.check(non_test_path, content, config)

        assert length(violations) == 1
        [violation] = violations
        assert violation.level == :error
        assert violation.rule == :fixture_usage
        assert String.contains?(violation.message, "No Factory module found")
      after
        # Restore factory file
        File.rename!(temp_path, factory_path)
      end
    end

    test "doesn't check factory existence when not requested", %{factory_path: factory_path} do
      # Temporarily move factory file to simulate missing factory
      temp_path = "#{factory_path}.bak"
      File.rename!(factory_path, temp_path)

      try do
        config = %{
          allowed: false,
          check_factory_exists: false,
          violation_level: :error
        }

        # Check with a non-test file
        content = "defmodule Some do\n  def x, do: 1\nend"
        non_test_path = "/some/non/test/file.ex"

        violations = Factory.check(non_test_path, content, config)

        assert violations == []
      after
        # Restore factory file
        File.rename!(temp_path, factory_path)
      end
    end
  end
end
