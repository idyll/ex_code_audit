defmodule ExCodeAudit.Analyzers.SchemaTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.Schema

  describe "name/0" do
    test "returns the correct rule name" do
      assert Schema.name() == :schema_location
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert Schema.description() != ""
      assert is_binary(Schema.description())
    end
  end

  describe "check/3" do
    test "identifies schema files" do
      content = """
      defmodule MyApp.User do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string

          timestamps()
        end
      end
      """

      config = %{
        path: "lib/my_app/schema/*.ex",
        violation_level: :error
      }

      # Test with a file in the wrong location
      violations = Schema.check("lib/my_app/user.ex", content, config)

      # Debug output
      IO.puts("Schema test - wrong location - violations: #{inspect(violations)}")

      IO.puts(
        "in_correct_location?: #{inspect(Schema.in_correct_location?("lib/my_app/user.ex", config))}"
      )

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :error
      assert violation.rule == :schema_location
      assert violation.file == "lib/my_app/user.ex"
      assert String.contains?(violation.message, "Schema file found in incorrect location")
    end

    test "ignores non-schema files" do
      content = """
      defmodule MyApp.UserController do
        use MyAppWeb, :controller

        def index(conn, _params) do
          users = Repo.all(User)
          render(conn, "index.html", users: users)
        end
      end
      """

      config = %{
        path: "lib/my_app/schema/*.ex",
        violation_level: :error
      }

      # Test with a non-schema file
      assert Schema.check("lib/my_app_web/controllers/user_controller.ex", content, config) == []
    end

    test "detects Repo calls in schema files" do
      content = """
      defmodule MyApp.Schema.User do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string

          timestamps()
        end

        def all do
          Repo.all(__MODULE__)
        end
      end
      """

      config = %{
        path: "lib/my_app/schema/*.ex",
        violation_level: :error,
        excludes: ["Repo."]
      }

      # Test with a schema file containing Repo calls
      violations = Schema.check("lib/my_app/schema/user.ex", content, config)

      # Debug output
      IO.puts("Schema test - repo calls - violations: #{inspect(violations)}")
      IO.puts("contains_repo_calls?: #{inspect(Schema.contains_repo_calls?(content))}")

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :schema_content
      assert violation.file == "lib/my_app/schema/user.ex"
      assert String.contains?(violation.message, "Schema file contains Repo calls")
    end

    test "accepts schema files in correct location" do
      content = """
      defmodule MyApp.Schema.User do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string

          timestamps()
        end
      end
      """

      config = %{
        path: "lib/my_app/schema/*.ex",
        violation_level: :error
      }

      # Test with a schema file in the correct location
      assert Schema.check("lib/my_app/schema/user.ex", content, config) == []
    end
  end
end
