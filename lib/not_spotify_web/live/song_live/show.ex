defmodule NotSpotifyWeb.SongLive.Show do
  use NotSpotifyWeb, :live_view

  alias NotSpotify.Media
  alias NotSpotify.Accounts
  alias NotSpotify.Repo

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    socket = assign(socket, current_user: Accounts.get_user_by_session_token(user_token))
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    song =
      id
      |> Media.get_song!()
      |> Repo.preload(:user)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:song, song)}
  end

  @impl true
  def handle_event("delete", %{"song-id" => id}, socket) do
    song = Media.get_song!(id)
    {:ok, _} = Media.delete_song(song)

    new_socket =
      socket
      |> push_navigate(to: "/", replace: true)

    {:noreply, new_socket}
  end

  defp page_title(:show), do: "Show Song"
  defp page_title(:edit), do: "Edit Song"
end
