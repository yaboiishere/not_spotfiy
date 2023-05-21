defmodule NotSpotifyWeb.SongLive.Index do
  use NotSpotifyWeb, :live_view

  alias NotSpotifyWeb.SortingHelpers
  alias NotSpotify.Media.Events
  alias NotSpotify.MusicBus
  alias NotSpotify.Media
  alias NotSpotify.Media.Song
  alias NotSpotify.Accounts
  alias NotSpotify.Accounts.User
  alias NotSpotify.Media.PlayingProcess

  alias NotSpotifyWeb.LayoutComponent
  alias NotSpotifyWeb.SongLive.UploadFormComponent
  alias NotSpotifyWeb.SongLive.QueueComponent

  @impl true
  def mount(params, %{"user_token" => user_token}, socket) do
    current_user = Accounts.get_user_by_session_token(user_token)

    MusicBus.join(User.process_name(current_user))

    new_socket =
      socket
      |> assign(
        current_user: current_user,
        sorting: SortingHelpers.default_values(),
        songs: Media.list_songs(params),
        query: "",
        queue: PlayingProcess.queue(current_user)
      )

    {:ok, new_socket}
  end

  def handle_params(%{"sort_by" => _} = params, _url, socket) do
    params
    |> SortingHelpers.changeset(socket.assigns.sorting)
    |> case do
      {:ok, sorting} ->
        socket
        |> assign(:songs, Media.list_songs(params))
        |> assign(:sorting, sorting)

      {:error, _changeset} ->
        socket
    end
    |> then(fn socket -> {:noreply, socket} end)
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

  defp apply_action(socket, :queue, _params) do
    socket
    |> assign(:page_title, "Queue")
    |> assign(:song, nil)
    |> show_queue_modal()
  end

  defp apply_action(socket, nil, params) do
    apply_action(socket, :index, params)
  end

  @impl true
  def handle_info({NotSpotifyWeb.SongLive.FormComponent, {:saved, song}}, socket) do
    {:noreply, stream_insert(socket, :songs, song)}
  end

  @impl true
  def handle_info({:update, :index, new_songs}, socket) do
    songs = socket.assigns.songs
    new_songs = new_songs |> Map.values()

    new_socket = assign(socket, :songs, songs ++ new_songs)

    {:noreply, push_patch(new_socket, to: Routes.live_path(socket, __MODULE__, %{}))}
  end

  def handle_info({:update, opts}, socket) do
    params = merge_params(socket, opts)
    path = Routes.live_path(socket, __MODULE__, params)

    new_socket = assign(socket, :songs, Media.list_songs(params))

    {:noreply, push_patch(new_socket, to: path)}
  end

  def handle_info({Media, %Media.Events.AddToQueue{song: song}}, socket) do
    new_socket =
      socket
      |> put_flash(:info, "Added #{song.title} to queue")
      |> assign(:queue, PlayingProcess.queue(socket.assigns.current_user))

    {:noreply, new_socket}
  end

  def handle_info({Media, Media.Events.ClearQueue}, socket) do
    new_socket =
      socket
      |> put_flash(:info, "Cleared queue")
      |> assign(:queue, PlayingProcess.queue(socket.assigns.current_user))

    {:noreply, new_socket}
  end

  def handle_info({Media, %Media.Events.NextCallback{}}, socket) do
    new_socket =
      socket
      |> assign(:queue, PlayingProcess.queue(socket.assigns.current_user))

    {:noreply, new_socket}
  end

  def handle_info({Media, %Media.Events.PrevCallback{}}, socket) do
    new_socket =
      socket
      |> assign(:queue, PlayingProcess.queue(socket.assigns.current_user))

    {:noreply, new_socket}
  end

  def handle_info({Media, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{songs: songs}} = socket) do
    song = Media.get_song!(id)
    {:ok, _} = Media.delete_song(song)

    new_socket = assign(socket, :songs, List.delete(songs, song))

    {:noreply, push_patch(new_socket, to: Routes.live_path(socket, __MODULE__, %{}))}
  end

  def handle_event("play", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    song = Media.get_song!(id)
    Media.play_song(song, current_user)
    queue = PlayingProcess.queue(current_user)

    {:noreply, assign(socket, song: song, playing: true, queue: queue)}
  end

  def handle_event("addToQueue", %{"id" => id}, socket) do
    song = Media.get_song!(id)
    current_user = socket.assigns.current_user
    MusicBus.broadcast(User.process_name(current_user), {Media, %Events.AddToQueue{song: song}})

    {:noreply, socket}
  end

  def handle_event("search", %{"query" => query}, socket) do
    new_socket = assign(socket, query: query)

    Process.send(self(), {:update, %{search_query: query}}, [])

    {:noreply, push_patch(new_socket, to: Routes.live_path(socket, __MODULE__, %{}))}
  end

  def handle_event(
        "remove_from_queue",
        %{"id" => index},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    PlayingProcess.remove_from_queue_by_index(current_user, index)

    new_socket =
      socket
      |> put_flash(:info, "Song removed from queue")
      |> assign(:queue, PlayingProcess.queue(current_user))
      |> push_patch(to: ~p"/songs/queue")

    {:noreply, new_socket}
  end

  def handle_event("clear_queue", _params, socket) do
    current_user = socket.assigns.current_user
    MusicBus.broadcast(User.process_name(current_user), {Media, Media.Events.ClearQueue})

    {:noreply, socket}
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

  defp show_queue_modal(socket) do
    LayoutComponent.show_modal(QueueComponent, %{
      id: :queue,
      patch: "/",
      confirm: {"Clear Queue", type: "submit", form: "queue-form"},
      cancel: "Close",
      song: socket.assigns.song,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user,
      queue: socket.assigns.queue
    })

    socket
  end

  defp merge_params(socket, overrides) do
    %{sorting: sorting, query: query} = socket.assigns

    %{}
    |> Map.merge(sorting)
    |> Map.merge(%{search_query: query})
    |> Map.merge(overrides)
  end
end
