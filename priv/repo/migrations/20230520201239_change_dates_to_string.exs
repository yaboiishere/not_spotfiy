defmodule NotSpotify.Repo.Migrations.ChangeDatesToString do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      modify :date_recorded, :string
      modify :date_released, :string
    end
  end
end
