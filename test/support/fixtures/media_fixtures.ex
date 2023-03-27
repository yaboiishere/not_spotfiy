defmodule NotSpotify.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotSpotify.Media` context.
  """

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, song} =
      attrs
      |> Enum.into(%{
        content_location: "some content_location",
        name: "some name",
        year: 42
      })
      |> NotSpotify.Media.create_song()

    song
  end
end
