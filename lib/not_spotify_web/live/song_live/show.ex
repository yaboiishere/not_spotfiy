defmodule NotSpotifyWeb.SongLive.Show do
  use NotSpotifyWeb, :live_view

  alias NotSpotify.Media
  alias NotSpotify.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    socket = assign(socket, current_user: Accounts.get_user_by_session_token(user_token))
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:song, Media.get_song!(id))}
  end

  defp page_title(:show), do: "Show Song"
  defp page_title(:edit), do: "Edit Song"
end
