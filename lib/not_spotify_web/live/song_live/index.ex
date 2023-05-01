defmodule NotSpotifyWeb.SongLive.Index do
  use NotSpotifyWeb, :live_view

  alias NotSpotify.MusicBus
  alias NotSpotify.Media
  alias NotSpotify.Media.Song
  alias NotSpotify.Accounts
  alias NotSpotify.Accounts.User
  alias NotSpotify.Repo

  alias NotSpotifyWeb.LayoutComponent
  alias NotSpotifyWeb.SongLive.UploadFormComponent

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    current_user = Accounts.get_user_by_session_token(user_token)

    MusicBus.join(User.process_name(current_user))

    new_socket =
      socket
      |> assign(:current_user, current_user)
      |> stream(:songs, Media.list_songs())

    {:ok, new_socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Song")
    |> assign(:song, Media.get_song!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Song")
    |> assign(:song, %Song{})
    |> show_upload_modal()
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Songs")
    |> assign(:song, nil)
  end

  defp apply_action(socket, nil, params) do
    apply_action(socket, :index, params)
  end

  @impl true
  def handle_info({NotSpotifyWeb.SongLive.FormComponent, {:saved, song}}, socket) do
    User
    |> Repo.all()
    |> Enum.each(fn user ->
      MusicBus.broadcast(User.process_name(user), {:update, :index})
    end)

    {:noreply, stream_insert(socket, :songs, song)}
  end

  @impl true
  def handle_info({:update, :index}, socket) do
    
    new_socket = stream(socket, :songs, Media.list_songs())
    {:noreply, new_socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    song = Media.get_song!(id)
    {:ok, _} = Media.delete_song(song)

    {:noreply, stream_delete(socket, :songs, song)}
  end

  defp show_upload_modal(socket) do
    LayoutComponent.show_modal(UploadFormComponent, %{
      id: :new,
      confirm: {"Save", type: "submit", form: "song-form"},
      patch: "/",
      song: socket.assigns.song,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user
    })

    socket
  end
end
