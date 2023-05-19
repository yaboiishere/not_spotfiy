defmodule NotSpotifyWeb.SortingHelpers do
  @moduledoc """
  Utilities for dealing with sortable state.
  """

  import Ecto.Changeset

  alias NotSpotify.Media.Song

  @types %{
    sort_by: {:parameterized, Ecto.Enum, Ecto.Enum.init(values: Song.columns())},
    sort_dir: {:parameterized, Ecto.Enum, Ecto.Enum.init(values: [:asc, :desc])}
  }

  @data %{
    sort_by: hd(Song.columns()),
    sort_dir: :asc
  }

  def changeset(params, current_data \\ @data) do
    {current_data, @types}
    |> cast(params, Map.keys(@types))
    |> apply_action(:insert)
  end

  def default_values(overrides \\ %{}), do: Map.merge(@data, overrides)
end
