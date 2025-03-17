defmodule ExCodeAudit.Analyzers.RepoCallsTest do
  use ExUnit.Case, async: true

  alias ExCodeAudit.Analyzers.RepoCalls

  describe "name/0" do
    test "returns the correct rule name" do
      assert RepoCalls.name() == :repo_calls
    end
  end

  describe "description/0" do
    test "returns a non-empty description" do
      assert RepoCalls.description() != ""
      assert is_binary(RepoCalls.description())
    end
  end

  describe "check/3" do
    test "identifies repo calls in inappropriate modules" do
      content = """
      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller

        def index(conn, _params) do
          users = MyApp.Repo.all(MyApp.User)
          render(conn, "index.html", users: users)
        end
      end
      """

      config = %{
        allowed_in: ["lib/my_app/operations/*.ex", "lib/my_app/queries/*.ex"],
        violation_level: :warning
      }

      # Test with a file containing repo calls but not in allowed paths
      violations =
        RepoCalls.check("lib/my_app_web/controllers/user_controller.ex", content, config)

      assert length(violations) == 1
      [violation] = violations
      assert violation.level == :warning
      assert violation.rule == :repo_calls
      assert violation.file == "lib/my_app_web/controllers/user_controller.ex"
      assert String.contains?(violation.message, "Repository call found in inappropriate module")
    end

    test "allows repo calls in appropriate modules" do
      content = """
      defmodule MyApp.Operations.CreateUser do
        def call(params) do
          %MyApp.User{}
          |> MyApp.User.changeset(params)
          |> MyApp.Repo.insert()
        end
      end
      """

      config = %{
        allowed_in: ["lib/my_app/operations/*.ex", "lib/my_app/queries/*.ex"],
        violation_level: :warning
      }

      # Test with a file containing repo calls in allowed paths
      assert RepoCalls.check("lib/my_app/operations/create_user.ex", content, config) == []
    end

    test "ignores files without repo calls" do
      content = """
      defmodule MyAppWeb.UserView do
        use MyAppWeb, :view

        def full_name(%{first_name: first, last_name: last}) do
          "\#{first} \#{last}"
        end
      end
      """

      config = %{
        allowed_in: ["lib/my_app/operations/*.ex", "lib/my_app/queries/*.ex"],
        violation_level: :warning
      }

      # Test with a file without repo calls
      assert RepoCalls.check("lib/my_app_web/views/user_view.ex", content, config) == []
    end
  end
end
