defmodule ToucanWeb.UserForgotPasswordLive do
  use ToucanWeb, :live_view

  alias Toucan.Accounts

  # ---------- RENDERING ----------
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Forgot your password?
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>
    </div>
    """
  end

  # ---------- LIFECYCLE CALLBACKS ----------
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  # ---------- EVENT HANDLERS ----------
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        fn token -> url(~p"/users/reset_password/\#{token}") end
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply, socket |> put_flash(:info, info) |> redirect(to: ~p"/")}
  end
end
