defmodule NotSpotify.MusicBus do
  @moduledoc """
  Functions for working with process groups.
  """
  alias NotSpotify.Media.PlayingProcess
  alias NotSpotify.Repo
  alias NotSpotify.Accounts.User

  def join(id) do
    id |> name() |> :pg.join(self())
  end

  def leave(id) do
    id |> name |> :pg.leave(self())
  end

  def broadcast(id, message) do
    User
    |> Repo.all()
    |> Enum.each(fn user ->
      PlayingProcess.start_if_not_running(user)
    end)

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
