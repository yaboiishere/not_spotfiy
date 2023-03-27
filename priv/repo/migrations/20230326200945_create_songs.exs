defmodule NotSpotify.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :name, :string
      add :year, :integer
      add :content_location, :string
      add :artist, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:songs, [:artist])
  end
end
