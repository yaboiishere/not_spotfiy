defmodule NotSpotify.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :title, :string, null: false
      add :album_artist, :string
      add :date_recorded, :naive_datetime
      add :date_released, :naive_datetime
      add :artist, :string, null: false
      add :duration, :integer, default: 0, null: false
      add :genre, :string
      add :mp3_url, :string, null: false
      add :mp3_filename, :string, null: false
      add :mp3_filepath, :string, null: false
      add :mp3_filesize, :integer, default: 0, null: false
      add :server_ip, :string, null: false

      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:songs, [:user_id])
    create unique_index(:songs, [:title, :artist, :user_id])
  end
end
