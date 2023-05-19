defmodule NotSpotify.PlayingProcessTest do
  alias NotSpotify.Accounts.User
  alias NotSpotify.MusicBus
  alias NotSpotify.MP3Stat
  alias NotSpotify.Media
  alias NotSpotify.Media.PlayingProcess
  alias NotSpotify.Accounts
  alias NotSpotify.Media.Song
  alias NotSpotify.Media.Events
  use NotSpotify.DataCase, async: false

  describe "PlayingProcess" do
    setup do
      {:ok, user} =
        Accounts.register_user(%{
          email: "admin@mitu.com",
          username: "admin",
          password: "AdminAdmin123"
        })

      :pg.get_members(:global) |> Enum.each(&Process.exit(&1, :kill))

      user_process = User.process_name(user)

      priv_dir = Path.join([:code.priv_dir(:not_spotify), "test_mp3_files"])

      songs =
        priv_dir
        |> File.ls!()
        |> Enum.map(fn file ->
          {:ok, %MP3Stat{duration: duration, path: mp3_path, title: title, artist: artist}} =
            MP3Stat.parse(Path.join([priv_dir, file]))

          Media.change_song(%Song{
            title: title,
            artist: artist,
            duration: duration,
            mp3_filename: Ecto.UUID.generate() <> ".mp3",
            mp3_filepath: mp3_path,
            mp3_url: "some_url",
            server_ip: "localhost"
          })
          |> Song.put_user(user)
          |> Repo.insert!()
        end)

      %{user: user, user_process: user_process, songs: songs}
    end

    test "plays a song", %{user: user, songs: songs, user_process: user_process} do
      song = Enum.at(songs, 0)
      assert PlayingProcess.active_song(user) == nil
      assert PlayingProcess.playing?(user) == false

      MusicBus.broadcast(user_process, {Media, %Events.Play{song: song}})

      assert PlayingProcess.playing?(user) == true
      assert PlayingProcess.active_song(user) == song

      MusicBus.broadcast(user_process, {Media, %Events.Pause{paused_at: 2}})
      elapsed = PlayingProcess.elapsed(user)
      assert elapsed > 0

      assert PlayingProcess.playing?(user) == false

      assert PlayingProcess.elapsed(user) == elapsed

      MusicBus.broadcast(user_process, {Media, %Events.Play{song: song, elapsed: elapsed}})

      assert PlayingProcess.elapsed(user) == elapsed
      assert PlayingProcess.playing?(user) == true

      song2 = Enum.at(songs, 1)
      MusicBus.broadcast(user_process, {Media, %Events.AddToQueue{song: song2}})

      assert PlayingProcess.song_queue(user) == [song2]

      MusicBus.broadcast(user_process, {Media, Events.Next})

      assert PlayingProcess.active_song(user) == song2
      assert PlayingProcess.song_queue(user) == []

      MusicBus.broadcast(user_process, {Media, Events.Prev})

      assert PlayingProcess.active_song(user) == song
      assert PlayingProcess.song_queue(user) == [song2]

      MusicBus.broadcast(user_process, {Media, Events.Stop})

      assert PlayingProcess.active_song(user) == nil
      assert PlayingProcess.song_queue(user) == [song2]
      assert PlayingProcess.playing?(user) == false
    end
  end
end
