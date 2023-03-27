defmodule NotSpotify.Media.Song do
  use Ecto.Schema
  import Ecto.Changeset

  schema "songs" do
    field :content_location, :string
    field :name, :string
    field :year, :integer

    belongs_to :artist, NotSpotify.Accounts.User

    timestamps()
  end

  @attrs ~w(name year content_location artist_id)a

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
  end
end
