defmodule NotSpotify.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias NotSpotify.Media.PlayingProcess
  alias NotSpotify.MusicBus
  alias NotSpotify.Accounts
  alias Ecto.Repo
  alias NotSpotify.Repo
  alias NotSpotify.Media.Song
  alias NotSpotify.Media.Events
  alias NotSpotify.Accounts.User

  alias NotSpotify.MP3Stat

  alias Ecto.Multi

  def list_songs do
    Song
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def get_song!(id), do: Repo.get!(Song, id)

  def create_song(attrs \\ %{}) do
    %Song{}
    |> Song.changeset(attrs)
    |> Repo.insert()
  end

  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> Repo.update()
  end

  def delete_song(%Song{} = song) do
    Repo.delete(song)
  end

  def change_song(song_or_changeset, attrs \\ %{})

  def change_song(%Song{} = song, attrs) do
    Song.changeset(song, attrs)
  end

  @keep_changes [:duration, :mp3_filesize, :mp3_filepath]
  def change_song(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Song{}
    |> change_song(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, @keep_changes))
  end

  def stopped?(%User{} = user) do
    PlayingProcess.stopped?(user)
  end

  def playing?(%User{} = user) do
    PlayingProcess.playing?(user)
  end

  def paused?(%User{} = user) do
    not PlayingProcess.playing?(user)
  end

  def play_song(%Song{id: id}, %User{} = user) do
    play_song(id, user)
  end

  def play_song(id, %User{} = user) do
    song = get_song!(id)

    MusicBus.broadcast(
      User.process_name(user),
      {NotSpotify.Media, %Events.Play{song: song, elapsed: 0}}
    )

    song
  end

  def pause_song(%User{} = user) do
    now = DateTime.truncate(DateTime.utc_now(), :second)

    MusicBus.broadcast(
      User.process_name(user),
      {NotSpotify.Media, %Events.Pause{paused_at: now}}
    )
  end

  def play_next_song([%Song{} = song | tail], %User{} = user) do
    play_song(song, user)
    tail
  end

  def play_prev_song([%Song{} = song | tail], %User{} = user) do
    play_song(song, user)
    tail
  end

  def get_current_active_song(%User{} = user) do
    PlayingProcess.active_song(user)
  end

  def elapsed_playback(%User{} = _user) do
    # PlayingProcess.elapsed_playback(user)
    0
  end

  # def elapsed_playback(%User{} = user) do
  #   cond do
  #     playing?(user) ->
  #       start_seconds =
  #         user.current_song_played_at
  #         |> DateTime.from_naive!("Etc/UTC")
  #         |> DateTime.to_unix()
  #
  #       System.os_time(:second) - start_seconds
  #
  #     paused?(user) ->
  #       DateTime.diff(user.current_song_paused_at, user.current_song_played_at, :second)
  #
  #     stopped?(user) ->
  #       0
  #   end
  # end

  def local_filepath(filename_uuid) when is_binary(filename_uuid) do
    dir = NotSpotify.config([:files, :uploads_dir])
    Path.join([dir, "songs", filename_uuid])
  end

  def parse_file_name(name) do
    case Regex.split(~r/[-–]/, Path.rootname(name), parts: 2) do
      [title] -> %{title: String.trim(title), artist: nil}
      [title, artist] -> %{title: String.trim(title), artist: String.trim(artist)}
    end
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    chset = Song.put_stats(changeset, stat)

    if error = chset.errors[:duration] do
      {:error, %{duration: error}}
    else
      {:ok, chset}
    end
  end

  def import_songs(%User{} = user, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    # refetch user for fresh song count
    user = Accounts.get_user!(user.id)

    # multi =
    #   Multi.new()
    #   |> Ecto.Multi.run(:starting_position, fn repo, _changes ->
    #     count = repo.one(from s in Song, where: s.user_id == ^user.id, select: count(s.id))
    #     {:ok, count - 1}
    #   end)

    multi =
      changesets
      |> Enum.reduce(Multi.new(), fn {ref, chset}, acc ->
        Ecto.Multi.insert(acc, {:song, ref}, fn %{} ->
          chset
          |> Song.put_user(user)
          |> Song.put_mp3_path()
          |> Song.put_server_ip()
        end)
      end)

    case Repo.transaction(multi) do
      {:ok, results} ->
        songs =
          results
          |> Enum.filter(&match?({{:song, _ref}, _}, &1))
          |> Enum.map(fn {{:song, ref}, song} ->
            consume_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
            {ref, song}
          end)

        # broadcast_imported(user, songs)

        {:ok, Enum.into(songs, %{})}

      {:error, failed_op, failed_val, _changes} ->
        failed_op =
          case failed_op do
            {:song, _number} -> "Invalid song (#{failed_val.changes.title})"
            :is_songs_count_updated? -> :invalid
            failed_op -> failed_op
          end

        {:error, {failed_op, failed_val}}
    end
  end

  defp store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!(Path.dirname(song.mp3_filepath))
    File.cp!(tmp_path, song.mp3_filepath)
  end
end
