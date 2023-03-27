defmodule NotSpotify.Media.Song do
  use Ecto.Schema
  import Ecto.Changeset

  schema "songs" do
    field :content_location, :string
    field :name, :string
    field :year, :integer
    field :artist, :id

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:name, :year, :content_location])
    |> validate_required([:name, :year, :content_location])
  end
end
