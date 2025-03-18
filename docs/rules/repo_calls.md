# Repository Calls Rule

The Repository Calls rule enforces proper separation of concerns by restricting where direct database operations can be performed in your application.

## Purpose

This rule ensures that database operations are properly organized by:

1. Limiting repository calls to designated modules (e.g., operations, queries)
2. Preventing repository calls in inappropriate modules (e.g., controllers, LiveView modules)
3. Maintaining a clean separation between business logic and data access

## Default Configuration

```elixir
repo_calls: [
  enabled: true,
  allowed_in: [
    "lib/:app_name/operations/*.ex",
    "lib/:app_name/queries/*.ex"
  ],
  excluded_paths: [
    "priv/repo/migrations/**",
    "priv/repo/seeds.exs",
    "lib/:app_name_web/telemetry.ex",
    "lib/:app_name_web.ex"
  ],
  violation_level: :warning
]
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `allowed_in` | list | `["lib/:app_name/operations/*.ex", "lib/:app_name/queries/*.ex"]` | List of path patterns where repo calls are allowed |
| `excluded_paths` | list | *See below* | List of paths to exclude from this rule |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

**Default excluded paths**:

```
[
  "priv/repo/migrations/**", 
  "priv/repo/seeds.exs",
  "lib/:app_name_web/telemetry.ex",
  "lib/:app_name_web.ex"
]
```

## How It Works

The analyzer scans your codebase for calls to repository functions like:

- Direct Repo calls (`Repo.get`, `Repo.all`, etc.)
- Schema operations that implicitly use the Repo (`schema.changeset |> Repo.insert()`)

It then checks if these calls are made in files that match the allowed patterns. If not, a violation is reported.

### Pattern Substitution

The `:app_name` variable in patterns is automatically replaced with your actual application name. For example, if your application is named `my_app`:

- `lib/:app_name/operations/*.ex` becomes `lib/my_app/operations/*.ex`
- `lib/:app_name_web/telemetry.ex` becomes `lib/my_app_web/telemetry.ex`

## Automatically Excluded Files

Certain types of files are automatically excluded from this rule, even if not explicitly listed in the `excluded_paths` configuration:

- Database migration files (`priv/repo/migrations/*`)
- Database seed files (`priv/repo/seeds.exs`)
- Telemetry files (`lib/:app_name_web/telemetry.ex`)
- Web module files (`lib/:app_name_web.ex`)

These exclusions are included by default because these files commonly need to make repository calls.

## Examples

### Valid Repository Pattern

```elixir
# lib/my_app/operations/create_user.ex
defmodule MyApp.Operations.CreateUser do
  alias MyApp.Repo
  alias MyApp.Schema.User

  def execute(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end
end
```

```elixir
# lib/my_app/queries/user_queries.ex
defmodule MyApp.Queries.UserQueries do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schema.User

  def get_active_users do
    User
    |> where(active: true)
    |> Repo.all()
  end
end
```

### Invalid Repository Pattern

```elixir
# lib/my_app_web/controllers/user_controller.ex
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias MyApp.Repo  # Direct Repo import in controller
  alias MyApp.Schema.User

  def index(conn, _params) do
    # Violation: Direct Repo call in controller
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end
end
```

## Common Issues and Solutions

### Repository Calls in Controllers

**Issue**:

```
⚠️ WARNING: Repository call found in inappropriate module
   Repo calls should be in modules matching: lib/my_app/operations/*.ex, lib/my_app/queries/*.ex
   File: lib/my_app_web/controllers/user_controller.ex
```

**Solution**:
Move the repository operations to an operations or queries module:

```elixir
# lib/my_app/queries/user_queries.ex
defmodule MyApp.Queries.UserQueries do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schema.User

  def list_users do
    Repo.all(User)
  end
end

# lib/my_app_web/controllers/user_controller.ex
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias MyApp.Queries.UserQueries

  def index(conn, _params) do
    users = UserQueries.list_users()
    render(conn, "index.html", users: users)
  end
end
```

### Repository Calls in LiveView Modules

**Issue**:

```
⚠️ WARNING: Repository call found in inappropriate module
   Repo calls should be in modules matching: lib/my_app/operations/*.ex, lib/my_app/queries/*.ex
   File: lib/my_app_web/live/user_live/index.ex
```

**Solution**:
Move the repository operations to operations or queries modules and call them from the LiveView:

```elixir
# Before (in LiveView)
def mount(_params, _session, socket) do
  users = MyApp.Repo.all(MyApp.Schema.User)
  {:ok, assign(socket, users: users)}
end

# After (in LiveView)
def mount(_params, _session, socket) do
  users = MyApp.Queries.UserQueries.list_users()
  {:ok, assign(socket, users: users)}
end
```

## Benefits of This Rule

Enforcing this rule offers several benefits:

1. **Testability**: Operations and queries can be mocked or replaced in tests
2. **Reusability**: Operations and queries can be reused across different parts of the application
3. **Maintainability**: Database logic is centralized and easier to update
4. **Performance**: Consolidating database operations makes it easier to identify and optimize queries

## Configuration Examples

### Customizing Allowed Locations

If your project uses a different structure, you can customize where repository calls are allowed:

```elixir
repo_calls: [
  allowed_in: [
    "lib/:app_name/data_access/*.ex",
    "lib/:app_name/services/**/*_service.ex"
  ]
]
```

### Adding Additional Exclusions

If you have specific files that need to make repository calls:

```elixir
repo_calls: [
  excluded_paths: [
    "priv/repo/migrations/**",
    "priv/repo/seeds.exs",
    "lib/:app_name_web/telemetry.ex",
    "lib/:app_name_web.ex",
    "lib/:app_name/special_case.ex"
  ]
]
```
