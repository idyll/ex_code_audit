defmodule MyApp.UserLive.Index do
  use Phoenix.LiveView
  alias MyApp.Accounts

  def mount(_params, session, socket) do
    current_user = session["current_user_id"] && Accounts.get_user!(session["current_user_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "users")

      # LIFECYCLE CALLBACKS
    end

    # EVENT HANDLERS
    # RENDERING
    socket =
      socket
      |> assign(:users, list_users())
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, assign(socket, :users, list_users())}
  end

  def handle_event("search", %{"q" => query}, socket) when byte_size(query) <= 100 do
    users = Accounts.search_users(query)
    {:noreply, assign(socket, :users, users)}
  end

  def handle_info({:user_created, user}, socket) do
    {:noreply, update(socket, :users, fn users -> [user | users] end)}
  end

  def handle_info({:user_updated, user}, socket) do
    {:noreply,
     update(socket, :users, fn users ->
       Enum.map(users, fn u -> if u.id == user.id, do: user, else: u end)
     end)}
  end

  def handle_info({:user_deleted, user}, socket) do
    {:noreply,
     update(socket, :users, fn users ->
       Enum.reject(users, fn u -> u.id == user.id end)
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Users</h1>

      <div class="mb-4">
        <form phx-change="search">
          <input type="text" name="q" placeholder="Search users..." />
        </form>
      </div>

      <table class="w-full">
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <%= for user <- @users do %>
            <tr id={"user-#{user.id}"}>
              <td><%= user.name %></td>
              <td><%= user.email %></td>
              <td><%= user.role %></td>
              <td class="text-right">
                <%= if @current_user && @current_user.role == "admin" do %>
                  <button
                    phx-click="delete"
                    phx-value-id={user.id}
                    class="text-red-500"
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </button>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>

      <%= if @current_user && @current_user.role == "admin" do %>
        <div class="mt-4">
          <.link navigate={~p"/users/new"} class="bg-blue-500 text-white px-4 py-2 rounded">
            New User
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %Accounts.User{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp list_users do
    Accounts.list_users()
  end
end
