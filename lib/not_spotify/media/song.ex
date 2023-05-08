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
    :date_recorded,
    :date_released,
    :artist,
    :genre,
    :duration,
    :mp3_url,
    :mp3_filename,
    :mp3_filepath,
    :mp3_filesize,
    :server_ip
  ]

  schema "songs" do
    field(:title, :string)
    field(:album_artist, :string)
    field(:date_recorded, :naive_datetime)
    field(:date_released, :naive_datetime)
    field(:artist, :string)
    field(:genre, :string)
    field(:duration, :integer)
    field(:mp3_url, :string)
    field(:mp3_filename, :string)
    field(:mp3_filepath, :string)
    field(:mp3_filesize, :integer, default: 0)
    field(:server_ip, :string)

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
end
