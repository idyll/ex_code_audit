defmodule DemoApp.DemoLiveView do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, items: [])}

    # LIFECYCLE CALLBACKS
  end

  def handle_para
  # EVENT HANDLERS

  # RENDERING
  ms(%{"id" => id}, _uri, socket) do
    # Fetch the item by id
    {:noreply, socket}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("add_item", %{"item" => item}, socket) do
    {:noreply, update(socket, :items, &[item | &1])}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Counter: <%= @count %></h1>
      <button phx-click="increment">+</button>
      <button phx-click="decrement">-</button>

      <h2>Items</h2>
      <ul>
        <%= for item <- @items do %>
          <li><%= item %></li>
        <% end %>
      </ul>

      <form phx-submit="add_item">
        <input type="text" name="item" placeholder="New item" />
        <button type="submit">Add</button>
      </form>
    </div>
    """
  end
end
