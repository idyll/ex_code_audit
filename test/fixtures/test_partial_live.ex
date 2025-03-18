defmodule ToucanWeb.PartialLive do
  use ToucanWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: [])}
  end

  # RENDERING is present, but LIFECYCLE CALLBACKS is missing
  # ---------- RENDERING ----------
  def render(assigns) do
    ~H"""
    <div>
      <h1>Partial Example</h1>
      <div>Content</div>
    </div>
    """
  end
end
