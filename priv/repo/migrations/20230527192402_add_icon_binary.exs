defmodule NotSpotify.Repo.Migrations.AddIconBinary do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add(:icon_binary, :bytea)
      add(:icon_type, :string)
    end
  end
end
