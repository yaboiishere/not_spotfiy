defmodule NotSpotifyWeb.PlayerLive do
  use NotSpotifyWeb, {:live_view, container: {:div, []}}

  alias NotSpotify.Media.PlayingProcess
  alias NotSpotify.MusicBus
  alias NotSpotify.Accounts.User
  alias NotSpotify.Media
  alias NotSpotify.Media.Song
  alias NotSpotify.Media.Events

  on_mount({NotSpotifyWeb.UserAuth, :current_user})

  def render(assigns) do
    ~H"""
    <!-- player -->
    <div
      id="audio-player"
      phx-hook="AudioPlayer"
      class="w-full bg-brand-grey rounded-3xl flex-around"
      role="region"
      aria-label="Player"
    >
      <div id="audio-ignore" phx-update="replace">
        <audio></audio>
      </div>
      <div class="text-brand-orange px-1 sm:px-3 lg:px-1 xl:px-3 grid grid-cols-3 items-center">
        <div class="flex-col">
          <div class="pr-6">
            <div class="min-w-1 max-w-xs flex-col space-y-0.5 justify-end overflow-hidden">
              <h1 class="text-right text-brand-orange text-sm sm:text-sm lg:text-sm xl:text-sm font-semibold truncate">
                <%= if @song, do: @song.title, else: raw("&nbsp;") %>
              </h1>
              <p class="text-right text-brand-orange text-sm sm:text-sm lg:text-sm xl:text-sm font-medium">
                <%= if @song, do: @song.artist, else: raw("&nbsp;") %>
              </p>
            </div>
          </div>
        </div>
        <div class="grid grid-cols-1">
          <div class="flex flex-row justify-around">
            <div class="mx-auto flex"></div>
            <!-- prev -->
            <button
              type="button"
              class="sm:block xl:block mx-auto scale-75 hover:text-orange-600"
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
              class="mx-auto scale-75 hover:text-orange-600"
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
                    class="text-brand-orange"
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
                    class=""
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
            <button
              type="button"
              class="mx-auto scale-75 hover:text-orange-600"
              phx-click={js_next()}
              aria-label="Next"
            >
              <svg width="17" height="18" viewBox="0 0 17 18" fill="none">
                <path d="M17 0H15V18H17V0Z" fill="currentColor" />
                <path d="M13 9L0 0V18L13 9Z" fill="currentColor" />
              </svg>
            </button>
            <!-- next -->
            <button
              type="button"
              class="mx-auto scale-75"
              phx-click="clear_queue"
              aria-label="Clear Queue"
            >
              <FontAwesome.LiveView.icon
                name="square-minus"
                type="regular"
                class="h-6 w-6 fill-brand-orange hover:fill-orange-600"
              />
            </button>
          </div>
          <div class="flex-row w-full pt-1 pb-3">
            <.progress_bar
              id="player-progress"
              class={"cursor-pointer #{if not @playing, do: "disabled", else: ""}"}
            />
          </div>
        </div>

        <div
          id="player-info"
          class="flex flex-col text-brand-orange justify-self-start text-sm font-medium tabular-nums pl-2 sm:pl-3 lg:pl-2 xl:pl-3 w-20 sm:w-full grid grid-cols-3"
          phx-update="ignore"
        >
          <div class="flex-col-1">
            <div id="player-time"></div>
            <div id="player-duration"></div>
          </div>
          <div class="float-right md-2 flex-col-1 my-auto grid grid-cols-2">
            <FontAwesome.LiveView.icon
              name="volume-high"
              type="solid"
              class="h-5 w-5 inline fill-brand-orange hover:fill-orange-600 justify-self-end mr-2"
            />
            <.progress_bar id="player-volume" class="cursor-pointer min-w-20 w-20 md:w-40 my-auto" />
          </div>
        </div>
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
    </div>
    <!-- /player -->
    """
  end

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns
    volume = PlayingProcess.get_volume(current_user)

    socket =
      socket
      |> assign(
        foo: true,
        song: nil,
        playing: false,
        current_user_id: current_user.id,
        own_profile?: false,
        song_queue: PlayingProcess.song_queue(current_user),
        songs: Media.list_songs(),
        volume: volume
      )
      |> push_set_volume(volume)

    MusicBus.join(User.process_name(current_user))

    {:ok, socket, layout: false, temporary_assigns: []}
  end

  def terminate(_reason, socket) do
    PlayingProcess.set_elapsed(socket.assigns.current_user, 0)

    MusicBus.broadcast(User.process_name(socket.assigns.current_user), {Media, Events.ClearQueue})

    MusicBus.leave(User.process_name(socket.assigns.current_user))
    {:ok, socket}
  end

  def handle_event("play_pause", _params, socket) do
    %{song: song, playing: playing, songs: songs} = socket.assigns
    current_user = socket.assigns.current_user
    process_active_song = PlayingProcess.active_song(current_user)

    song =
      cond do
        is_nil(song) && is_nil(process_active_song) -> List.first(songs)
        is_nil(song) && process_active_song -> PlayingProcess.active_song(current_user)
        true -> song
      end

    cond do
      song && playing ->
        Media.pause_song(current_user)
        {:noreply, assign(socket, playing: false)}

      song ->
        Media.play_song(song, current_user)
        {:noreply, assign(socket, playing: true)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("next_song", _, socket) do
    %{song: song, current_user: current_user} = socket.assigns

    if song do
      Media.play_next_song(current_user)
    end

    {:noreply, socket}
  end

  def handle_event("prev_song", _, socket) do
    %{song: song, current_user: current_user} = socket.assigns

    if song do
      Media.play_prev_song(current_user)
    end

    {:noreply, socket}
  end

  def handle_event("next_song_auto", _, socket) do
    if socket.assigns.song do
      Media.play_next_song(socket.assigns.current_user)
    end

    {:noreply, socket}
  end

  def handle_event("clear_queue", _, socket) do
    current_user = socket.assigns.current_user
    MusicBus.broadcast(User.process_name(current_user), {Media, Media.Events.ClearQueue})

    {:noreply, socket}
  end

  def handle_event("volume", %{"volume" => volume}, socket) do
    current_user = socket.assigns.current_user

    PlayingProcess.set_volume(current_user, volume)

    new_socket =
      socket
      |> assign(volume: volume)

    {:noreply, new_socket}
  end

  def handle_event("paused_at", %{"paused_at" => paused_at}, socket) do
    set_elapsed(socket.assigns.current_user, paused_at)

    {:noreply, socket}
  end

  def handle_event("seeked", %{"seeked" => seeked}, socket) do
    set_elapsed(socket.assigns.current_user, seeked)

    {:noreply, socket}
  end

  def handle_info(:play_current, socket) do
    {:noreply, play_current_song(socket)}
  end

  def handle_info({Media, %Media.Events.Pause{}}, socket) do
    {:noreply, push_pause(socket)}
  end

  def handle_info({Media, %Media.Events.Play{elapsed: elapsed} = play}, socket) do
    PlayingProcess.set_elapsed(socket.assigns.current_user, elapsed)
    {:noreply, play_song(socket, play.song, elapsed)}
  end

  def handle_info({Media, %Media.Events.NextCallback{song: song}}, socket) do
    {:noreply, play_song(socket, song, 0)}
  end

  def handle_info({Media, %Media.Events.PrevCallback{song: song}}, socket) do
    {:noreply, play_song(socket, song, 0)}
  end

  def handle_info({Media, Media.Events.Stop}, socket) do
    {:noreply, stop_song(socket)}
  end

  def handle_info({Media, _}, socket), do: {:noreply, socket}
  def handle_info({:update, _}, socket), do: {:noreply, socket}

  defp play_song(socket, %Song{} = song, elapsed) do
    socket
    |> push_play(song, elapsed)
    |> assign(song: song, playing: true, page_title: song_title(song))
  end

  defp stop_song(socket) do
    socket
    |> push_event("stop", %{})
    |> assign(song: nil, playing: false, page_title: "Listing Songs")
  end

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
        ip: to_string(song.server_ip),
        size: song.mp3_filesize,
        uuid: song.mp3_filename
      })

    push_event(socket, "play", %{
      artist: song.artist,
      title: song.title,
      paused: Media.paused?(socket.assigns.current_user),
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

  defp push_set_volume(socket, volume) do
    push_event(socket, "set_volume", %{volume: volume})
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

  defp set_elapsed(current_user, elapsed) do
    seeked = round(elapsed)

    PlayingProcess.set_elapsed(current_user, seeked)
  end
end
