defmodule NotSpotifyWeb.SongLive.QueueComponent do
  use NotSpotifyWeb, :live_component

  def render(assigns) do
    ~H"""
    <form id="queue-form" phx-submit="clear_queue">
      <.table
        id="queue-modal"
        rows={@queue}
        row_click={fn song -> JS.push("play", value: %{id: song.id}) end}
        row_id={fn song -> "queue-song-#{song.id}" end}
      >
        <:col :let={{song, _i}} label="Title" name="title" class="break-all"><%= song.title %></:col>
        <:col :let={{song, _i}} label="Artist" name="artist" class="break-all">
          <%= song.artist %>
        </:col>

        <:col :let={{song, _i}} label="Duration" name="duration" hidden>
          <%= song.duration |> formatted_length %>
        </:col>

        <:action :let={{_song, index}}>
          <.link phx-click="remove_from_queue" phx-value-id={index}>
            <FontAwesome.LiveView.icon
              name="circle-minus"
              type="solid"
              class="h-5 w-5 inline fill-zinc-100 hover:fill-zinc-300"
            />
          </.link>
        </:action>
      </.table>
    </form>
    """
  end
end
