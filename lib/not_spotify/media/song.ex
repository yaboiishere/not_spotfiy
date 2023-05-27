defmodule NotSpotify.Media.Song do
  @moduledoc """
  The Song context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias NotSpotify.Accounts

  @attrs [
    :title,
    :album_artist,
    :album,
    :date_recorded,
    :date_released,
    :artist,
    :genre,
    :duration,
    :mp3_url,
    :mp3_filename,
    :mp3_filepath,
    :mp3_filesize,
    :server_ip,
    :icon_binary,
    :icon_type
  ]

  def columns(), do: @attrs

  schema "songs" do
    field(:title, :string)
    field(:album_artist, :string)
    field(:date_recorded, :string)
    field(:date_released, :string)
    field(:artist, :string)
    field(:album, :string)
    field(:genre, :string)
    field(:duration, :integer)
    field(:mp3_url, :string)
    field(:mp3_filename, :string)
    field(:mp3_filepath, :string)
    field(:mp3_filesize, :integer, default: 0)
    field(:server_ip, :string)
    field(:icon_binary, :binary)
    field(:icon_type, :string)

    belongs_to(:user, NotSpotify.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, @attrs)
    |> validate_required([:artist, :title])
    |> unique_constraint(:title,
      message: "is a duplicated from another song",
      name: "songs_user_id_title_artist_index"
    )
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %NotSpotify.MP3Stat{} = stat) do
    changeset
    |> put_duration(stat.duration)
    |> put_mp3_data(stat)
    |> Ecto.Changeset.put_change(:mp3_filesize, stat.size)
  end

  defp put_duration(%Ecto.Changeset{} = changeset, duration) when is_integer(duration) do
    changeset
    |> Ecto.Changeset.change(%{duration: duration})
    |> Ecto.Changeset.validate_number(:duration,
      greater_than: 0,
      less_than: 1200,
      message: "must be less than 20 minutes"
    )
  end

  def put_mp3_path(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      filename = Ecto.UUID.generate() <> ".mp3"
      filepath = NotSpotify.Media.local_filepath(filename)

      changeset
      |> Ecto.Changeset.put_change(:mp3_filename, filename)
      |> Ecto.Changeset.put_change(:mp3_filepath, filepath)
      |> Ecto.Changeset.put_change(:mp3_url, mp3_url(filename))
    else
      changeset
    end
  end

  def put_server_ip(%Ecto.Changeset{} = changeset) do
    server_ip = NotSpotify.config([:files, :server_ip])
    Ecto.Changeset.cast(changeset, %{server_ip: server_ip}, [:server_ip])
  end

  defp mp3_url(filename) do
    %{scheme: scheme, host: host, port: port} = Enum.into(NotSpotify.config([:files, :host]), %{})
    URI.to_string(%URI{scheme: scheme, host: host, port: port, path: "/files/#{filename}"})
  end

  defp put_mp3_data(changeset, stat) do
    %{tags: tags} = stat

    changeset
    |> maybe_add_tag(tags, "TIT2", :title)
    |> maybe_add_tag(tags, "TPE1", :artist)
    |> maybe_add_tag(tags, "TALB", :album)
    |> maybe_add_tag(tags, "TCON", :genre)
    |> maybe_add_tag(tags, "TYER", :date_released)
    |> maybe_add_icon(tags)
  end

  defp get_tag(tags, key) do
    tags |> Map.get(key, []) |> List.first("")
  end

  defp maybe_add_tag(changeset, tags, tag, key) do
    tags
    |> get_tag(tag)
    |> case do
      "" -> changeset
      value -> Ecto.Changeset.put_change(changeset, key, value)
    end
  end

  defp maybe_add_icon(changeset, tags) do
    tags
    |> Map.get("APIC", "")
    |> case do
      "" ->
        changeset

      {type, _, _, binary} ->
        changeset
        |> Ecto.Changeset.put_change(:icon_binary, binary)
        |> Ecto.Changeset.put_change(:icon_type, type)
    end
  end
end
