# LiveView Sections Rule

The LiveView Sections rule enforces consistent organization of LiveView and LiveComponent modules by requiring specific comment section headers to break up the code into logical groups.

## Purpose

This rule ensures that LiveView and LiveComponent modules are consistently organized, making them easier to navigate and understand by:

1. Dividing the code into logical sections
2. Providing clear visual indicators of where specific types of functions are located
3. Ensuring important callbacks and functions are properly organized

## Default Configuration

```elixir
live_view_sections: [
  enabled: true,
  required: [
    "LIFECYCLE CALLBACKS",
    "EVENT HANDLERS", 
    "RENDERING"
  ],
  check_external_templates: true,
  check_component_structure: true,
  violation_level: :warning
]
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Whether this rule is enabled |
| `required` | list | `["LIFECYCLE CALLBACKS", "EVENT HANDLERS", "RENDERING"]` | List of required section labels |
| `check_external_templates` | boolean | `true` | Whether to check for external templates usage |
| `check_component_structure` | boolean | `true` | Whether to check component structure |
| `excluded_rules` | list | `[]` | List of specific rules to exclude (e.g., `["component_props_docs"]`) |
| `violation_level` | atom | `:warning` | Level for violations (`:warning` or `:error`) |

## How It Works

The analyzer scans LiveView and LiveComponent files for:

1. **Section Headers**: Required comment sections that divide the code
2. **External Templates**: Use of external template files instead of embedded HEEx
3. **Component Structure**: Proper structure of LiveComponents

The rule identifies files as LiveView or LiveComponent based on:

- Module usage (`use Phoenix.LiveView`, `use Phoenix.LiveComponent`)
- Presence of characteristic callbacks (`mount/3`, `render/1`, `handle_event/3`)

### Section Headers Format

Section headers must be formatted as comment lines with uppercase text:

```elixir
# LIFECYCLE CALLBACKS
```

Decorated section headers are also supported:

```elixir
# ---------- LIFECYCLE CALLBACKS ----------
```

### Intelligently Required Sections

As of version 0.1.0, the analyzer intelligently checks for section headers based on the functions present in the file. For example:

- If a file has no event handler functions, the "EVENT HANDLERS" section isn't required
- If a file has no lifecycle callbacks, the "LIFECYCLE CALLBACKS" section isn't required

This prevents false positives in files that don't need certain sections.

## Required Sections by Default

1. **LIFECYCLE CALLBACKS** - For mounting, initialization, and other lifecycle functions
   - `mount/3`
   - `update/2`
   - `init/1`
   - `terminate/2`
   - `on_mount/1`
   - `handle_params/3`
   - `handle_continue/2`

2. **EVENT HANDLERS** - For event handling functions
   - `handle_event/3`
   - `handle_info/2`
   - `handle_call/3`
   - `handle_cast/2`

3. **RENDERING** - For rendering and presentation functions
   - `render/1`
   - `component/1`
   - `page_title/1`

## Component Structure Checks

When `check_component_structure` is enabled, components are also checked for:

1. **Embedded HEEx Templates** - Components should use embedded templates
2. **Update Callback** - Stateful components should include an update callback
3. **Documented Props** - Component properties should be documented

You can selectively disable certain component checks without disabling all of them by using the `excluded_rules` option:

```yaml
live_view_sections:
  excluded_rules:
    - component_props_docs
```

This will disable only the props documentation check while keeping other component structure checks enabled.

Documentation can be in any of these formats:

- Using `@moduledoc` with a "## Props" section
- Using `@moduledoc` with `{:prop, ...}` syntax
- Using `@doc` with `{:prop, ...}` syntax

## External Templates Check

When `check_external_templates` is enabled, the analyzer flags usage of external templates:

- `Phoenix.View.render/3`
- `Phoenix.Template.render/2`
- `render_template/2`
- `render(assigns, "template.html")`
- `render(assigns, :template)`

## Auto-Fix Support

This rule supports auto-fixing with `mix code.audit --fix`. When used, the tool will:

1. Find LiveView files with missing sections
2. Determine where to insert each section
3. Add the required section headers in appropriate locations

### Fix Options

| Option | Description |
|--------|-------------|
| `--fix` | Apply fixes to all files with violations |
| `--preview` | Show a diff-style preview without making changes |
| `--force` | Recreate section headers even if they already exist |

### Preview Example

```
## Insert LIFECYCLE CALLBACKS at line 6:
  3: 
  4:   def mount(_params, _session, socket) do
  5:     {:ok, assign(socket, count: 0)}
  6:   end
+ 6: # ---------- LIFECYCLE CALLBACKS ----------
  lib/my_app_web/live/user_live.ex:6
```

## Examples

### Valid LiveView File

```elixir
defmodule MyAppWeb.UserLive do
  use MyAppWeb, :live_view
  alias MyApp.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: [])}
  end

  # ---------- LIFECYCLE CALLBACKS ----------
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, page: String.to_integer(params["page"] || "1"))}
  end

  # ---------- EVENT HANDLERS ----------
  def handle_event("search", %{"query" => query}, socket) do
    users = Accounts.search_users(query)
    {:noreply, assign(socket, users: users)}
  end

  def handle_info({:user_created, user}, socket) do
    {:noreply, update(socket, :users, &[user | &1])}
  end

  # ---------- RENDERING ----------
  def render(assigns) do
    ~H"""
    <div>
      <h1>Users</h1>
      <ul>
        <%= for user <- @users do %>
          <li><%= user.name %></li>
        <% end %>
      </ul>
    </div>
    """
  end
end
```

### Valid Component File

```elixir
defmodule MyAppWeb.Components.Button do
  @moduledoc """
  Button component for the application.
  
  ## Props
  
  * `type` - The button type (default: "button")
  * `class` - Additional CSS classes
  * `disabled` - Whether the button is disabled
  * `click` - The click event handler
  """
  use Phoenix.Component

  # ---------- RENDERING ----------
  def render(assigns) do
    ~H"""
    <button
      type={@type || "button"}
      class={["btn", @class]}
      disabled={@disabled}
      phx-click={@click}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

## Common Issues and Solutions

### Missing Section Headers

**Issue**:

```
⚠️ WARNING: LiveView missing labeled sections
   Missing sections: ["LIFECYCLE CALLBACKS", "EVENT HANDLERS"]
   File: lib/my_app_web/live/user_live.ex
```

**Solution**:
Add section headers above the corresponding function groups:

```elixir
# ---------- LIFECYCLE CALLBACKS ----------
def mount(_params, _session, socket) do
  # ...
end

# ---------- EVENT HANDLERS ----------
def handle_event("click", _params, socket) do
  # ...
end
```

### External Templates Usage

**Issue**:

```
⚠️ WARNING: LiveView uses external templates
   LiveView components should use embedded HEEx templates instead of external template files
   File: lib/my_app_web/live/product_component.ex
```

**Solution**:
Replace external template rendering:

```elixir
# Before
def render(assigns) do
  Phoenix.View.render(MyAppWeb.ProductView, "product.html", assigns)
end

# After
def render(assigns) do
  ~H"""
  <div class="product">
    <h2><%= @product.name %></h2>
    <p><%= @product.description %></p>
  </div>
  """
end
```

### Missing Component Documentation

**Issue**:

```
⚠️ WARNING: LiveView component structure issue
   Component props are not documented with @moduledoc or @doc
   File: lib/my_app_web/components/card.ex
```

**Solution**:
Add documentation for component props:

```elixir
@moduledoc """
A card component for displaying content with a title and body.

## Props

* `title` - The card title
* `class` - Additional CSS classes to apply
"""
```
