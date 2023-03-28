defmodule NotSpotifyWeb.PlayerLive do
  use NotSpotifyWeb, {:live_view, container: {:div, []}}

  alias NotSpotify.Accounts.User
  alias NotSpotify.{Accounts, Media}
  alias NotSpotify.Media.Song

  on_mount {NotSpotifyWeb.UserAuth, :current_user}

  def render(assigns) do
    ~H"""
    <!-- player -->
    <div id="audio-player" phx-hook="AudioPlayer" class="w-full" role="region" aria-label="Player">
      <div id="audio-ignore" phx-update="ignore">
        <audio></audio>
      </div>
      <div class="bg-white dark:bg-gray-800 p-4">
        <div class="flex items-center space-x-3.5 sm:space-x-5 lg:space-x-3.5 xl:space-x-5">
          <div class="pr-5">
            <div class="min-w-0 max-w-xs flex-col space-y-0.5">
              <h2 class="text-black dark:text-white text-sm sm:text-sm lg:text-sm xl:text-sm font-semibold truncate">
                <%= if @song, do: @song.title, else: raw("&nbsp;") %>
              </h2>
              <p class="text-gray-500 dark:text-gray-400 text-sm sm:text-sm lg:text-sm xl:text-sm font-medium">
                <%= if @song, do: @song.artist, else: raw("&nbsp;") %>
              </p>
            </div>
          </div>
          <.progress_bar id="player-progress" />

          <div
            id="player-info"
            class="text-gray-500 dark:text-gray-400 flex-row justify-between text-sm font-medium tabular-nums"
            phx-update="ignore"
          >
            <div id="player-time"></div>
            <div id="player-duration"></div>
          </div>
        </div>
      </div>
      <div class="bg-gray-50 text-black dark:bg-gray-900 dark:text-white px-1 sm:px-3 lg:px-1 xl:px-3 grid grid-cols-5 items-center">
        <div class="mx-auto flex"></div>

        <%= if is_nil(@user) or @own_profile? do %>
          <!-- prev -->
          <button
            type="button"
            class="sm:block xl:block mx-auto scale-75"
            phx-click={js_prev()}
            aria-label="Previous"
          >
            <svg width="17" height="18">
              <path d="M0 0h2v18H0V0zM4 9l13-9v18L4 9z" fill="currentColor" />
            </svg>
          </button>
          <!-- /prev -->

          <!-- play/pause -->
          <button
            type="button"
            class="mx-auto scale-75"
            phx-click={js_play_pause()}
            aria-label={
              if @playing do
                "Pause"
              else
                "Play"
              end
            }
          >
            <%= if @playing do %>
              <svg id="player-pause" width="50" height="50" fill="none">
                <circle
                  class="text-gray-300 dark:text-gray-500"
                  cx="25"
                  cy="25"
                  r="24"
                  stroke="currentColor"
                  stroke-width="1.5"
                />
                <path d="M18 16h4v18h-4V16zM28 16h4v18h-4z" fill="currentColor" />
              </svg>
            <% else %>
              <svg
                id="player-play"
                width="50"
                height="50"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <circle
                  id="svg_1"
                  stroke-width="0.8"
                  stroke="currentColor"
                  r="11.4"
                  cy="12"
                  cx="12"
                  class="text-gray-300 dark:text-gray-500"
                />
                <path
                  stroke="null"
                  fill="currentColor"
                  transform="rotate(90 12.8947 12.3097)"
                  id="svg_6"
                  d="m9.40275,15.10014l3.49194,-5.58088l3.49197,5.58088l-6.98391,0z"
                  stroke-width="1.5"
                  fill="none"
                />
              </svg>
            <% end %>
          </button>
          <!-- /play/pause -->

          <!-- next -->
          <button type="button" class="mx-auto scale-75" phx-click={js_next()} aria-label="Next">
            <svg width="17" height="18" viewBox="0 0 17 18" fill="none">
              <path d="M17 0H15V18H17V0Z" fill="currentColor" />
              <path d="M13 9L0 0V18L13 9Z" fill="currentColor" />
            </svg>
          </button>
          <!-- next -->
        <% else %>
          <button type="button" class="mx-auto scale-75"></button>
          <!-- stop button -->
          <button
            type="button"
            class="mx-auto scale-75"
            phx-click={
              JS.push("switch_profile", value: %{user_id: nil}, target: "#player", loading: "#player")
            }
          >
            <.icon name={:stop} class="h-12 w-12" />
          </button>
          <!-- stop button -->
        <% end %>
      </div>

      <.modal
        id="enable-audio"
        on_confirm={js_listen_now() |> hide_modal("enable-audio")}
        data-js-show={show_modal("enable-audio")}
      >
        <:title>Start Listening now</:title>
        Your browser needs a click event to enable playback
        <:confirm>Listen Now</:confirm>
      </.modal>

      <%= if @user do %>
        <.modal id="not-authorized" on_confirm={hide_modal("not-authorized")}>
          <:title>You can't do that</:title>
          Only <%= @user.username %> can control playback
          <:confirm>Ok</:confirm>
        </.modal>
      <% end %>
    </div>
    <!-- /player -->
    """
  end

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Accounts.subscribe(current_user.id)
    end

    socket =
      socket
      |> assign(
        foo: true,
        song: nil,
        playing: false,
        current_user_id: current_user.id,
        own_profile?: false,
        song_queue: []
      )

    {:ok, socket, layout: false, temporary_assigns: []}
  end

  def handle_event("play_pause", _, socket) do
    %{song: song, playing: playing} = socket.assigns
    song = Media.get_song!(song.id)

    cond do
      song && playing ->
        Media.pause_song(song)
        {:noreply, assign(socket, playing: false)}

      song ->
        Media.play_song(song)
        {:noreply, assign(socket, playing: true)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("next_song", _, socket) do
    %{song: song, song_queue: song_queue, current_user: current_user} = socket.assigns

    if song do
      Media.play_next_song(song_queue, current_user)
    end

    {:noreply, socket}
  end

  def handle_event("prev_song", _, socket) do
    %{song: song, song_queue: song_queue, current_user: current_user} = socket.assigns

    if song do
      Media.play_prev_song(song_queue, current_user)
    end

    {:noreply, socket}
  end

  def handle_event("next_song_auto", _, socket) do
    if socket.assigns.song do
      # Media.play_next_song_auto(socket.assigns.song_queue)
      Media.play_next_song(socket.assigns.song_queue, socket.assigns.current_user)
    end

    {:noreply, socket}
  end

  def handle_info(:play_current, socket) do
    {:noreply, play_current_song(socket)}
  end

  def handle_info({Media, %Media.Events.Pause{}}, socket) do
    {:noreply, push_pause(socket)}
  end

  def handle_info({Media, %Media.Events.Play{} = play}, socket) do
    {:noreply, play_song(socket, play.song, play.elapsed)}
  end

  def handle_info({Media, _}, socket), do: {:noreply, socket}

  defp play_song(socket, %Song{} = song, elapsed) do
    socket
    |> push_play(song, elapsed)
    |> assign(song: song, playing: true, page_title: song_title(song))
  end

  # defp stop_song(socket) do
  #   socket
  #   |> push_event("stop", %{})
  #   |> assign(song: nil, playing: false, page_title: "Listing Songs")
  # end

  defp song_title(%{artist: artist, title: title}) do
    "#{title} - #{artist} (Now Playing)"
  end

  defp play_current_song(socket) do
    current_user = socket.assigns.current_user
    song = Media.get_current_active_song(current_user)

    cond do
      song && Media.playing?(current_user) ->
        play_song(socket, song, Media.elapsed_playback(current_user))

      song && Media.paused?(song) ->
        assign(socket, song: song, playing: false)

      true ->
        socket
    end
  end

  defp push_play(socket, %Song{} = song, elapsed) do
    token =
      Phoenix.Token.encrypt(socket.endpoint, "file", %{
        vsn: 1,
        # ip: to_string(song.server_ip),
        size: song.mp3_filesize,
        uuid: song.mp3_filename
      })

    push_event(socket, "play", %{
      artist: song.artist,
      title: song.title,
      paused: User.paused?(socket.assigns.current_user),
      elapsed: elapsed,
      duration: song.duration,
      token: token,
      url: song.mp3_url
    })
  end

  defp push_pause(socket) do
    socket
    |> push_event("pause", %{})
    |> assign(playing: false)
  end

  defp js_play_pause() do
    JS.push("play_pause")
    |> JS.dispatch("js:play_pause", to: "#audio-player")
  end

  defp js_prev() do
    JS.push("prev_song")
  end

  defp js_next() do
    JS.push("next_song")
  end

  defp js_listen_now(js \\ %JS{}) do
    JS.dispatch(js, "js:listen_now", to: "#audio-player")
  end
end
