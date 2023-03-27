defmodule NotSpotifyWeb.SongController do
  use NotSpotifyWeb, :controller

  def index(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    live_render(conn, NotSpotifyWeb.SongLive.Index)
  end
end
