defmodule ToucanWeb.TestIndentedLive do
  use ToucanWeb, :live_component
  import ToucanWeb.MenuComponent

  def render(assigns) do
    ~H"""
    <div id="primary-menu">
      <.menu current_user={@current_user} current_page={@current_page} />
    </div>
    """
  end
end
