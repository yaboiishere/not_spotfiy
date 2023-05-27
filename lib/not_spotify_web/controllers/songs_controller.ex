defmodule NotSpotifyWeb.SongsController do
  use NotSpotifyWeb, :controller

  alias NotSpotify.Repo
  alias NotSpotify.Media.Song

  def show(conn, %{"id" => id}) do
    Song
    |> Repo.get(id)
    |> case do
      nil ->
        conn
        |> send_resp(404, "Not found")

      %Song{icon_type: nil} ->
        conn
        |> send_resp(406, File.read!("#{:code.priv_dir(:not_spotify)}/static/images/logo.png"))

      %Song{icon_type: icon_type, icon_binary: icon_binary} ->
        conn
        |> put_resp_content_type(icon_type)
        |> send_resp(200, icon_binary)
    end
  end
end
