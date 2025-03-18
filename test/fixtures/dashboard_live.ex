defmodule ToucanWeb.DashboardLive do
  use ToucanWeb, :live_view
  alias Toucan.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, current_page: :dashboard)}
  end

  def render(%{live_action: :dashboard} = assigns) do
    ~H"""
    <div class="space-y-4">
      <h1 class="text-center text-3xl font-bold">Welcome</h1>
      <p class="text-gray-600">
        Logged in as: <span class="font-medium">{@current_user.email}</span>
      </p>
    </div>
    """
  end

  def handle_event("navigate", %{"to" => path}, socket) do
    {:noreply, push_navigate(socket, to: path)}
  end
end
