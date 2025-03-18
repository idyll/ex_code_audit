defmodule ToucanWeb.DashboardLive do
  use ToucanWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: [])}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Dashboard</h1>
      <div>Content</div>
    </div>
    """
  end
end
