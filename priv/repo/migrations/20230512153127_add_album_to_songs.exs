defmodule NotSpotify.Repo.Migrations.AddAlbumToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :album, :string
    end
  end
end
