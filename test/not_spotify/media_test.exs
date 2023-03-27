defmodule NotSpotify.MediaTest do
  use NotSpotify.DataCase

  alias NotSpotify.Media

  describe "songs" do
    alias NotSpotify.Media.Song

    import NotSpotify.MediaFixtures

    @invalid_attrs %{content_location: nil, name: nil, year: nil}

    test "list_songs/0 returns all songs" do
      song = song_fixture()
      assert Media.list_songs() == [song]
    end

    test "get_song!/1 returns the song with given id" do
      song = song_fixture()
      assert Media.get_song!(song.id) == song
    end

    test "create_song/1 with valid data creates a song" do
      valid_attrs = %{content_location: "some content_location", name: "some name", year: 42}

      assert {:ok, %Song{} = song} = Media.create_song(valid_attrs)
      assert song.content_location == "some content_location"
      assert song.name == "some name"
      assert song.year == 42
    end

    test "create_song/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_song(@invalid_attrs)
    end

    test "update_song/2 with valid data updates the song" do
      song = song_fixture()
      update_attrs = %{content_location: "some updated content_location", name: "some updated name", year: 43}

      assert {:ok, %Song{} = song} = Media.update_song(song, update_attrs)
      assert song.content_location == "some updated content_location"
      assert song.name == "some updated name"
      assert song.year == 43
    end

    test "update_song/2 with invalid data returns error changeset" do
      song = song_fixture()
      assert {:error, %Ecto.Changeset{}} = Media.update_song(song, @invalid_attrs)
      assert song == Media.get_song!(song.id)
    end

    test "delete_song/1 deletes the song" do
      song = song_fixture()
      assert {:ok, %Song{}} = Media.delete_song(song)
      assert_raise Ecto.NoResultsError, fn -> Media.get_song!(song.id) end
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = Media.change_song(song)
    end
  end
end
