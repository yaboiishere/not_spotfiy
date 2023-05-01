defmodule NotSpotify.MusicBus do
  def join(id) do
    id |> name() |> :pg.join(self())
  end

  def leave(id) do
    id |> name |> :pg.leave(self())
  end

  def broadcast(id, message) do
    id
    |> name()
    |> :pg.get_members()
    |> Enum.each(fn pid ->
      send(pid, message)
    end)

  end

  defp name(id) do
    {__MODULE__, id}
  end
end
