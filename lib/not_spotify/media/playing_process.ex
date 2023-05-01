defmodule NotSpotify.Media.PlayingProcess do
  use GenServer

  alias NotSpotify.Media
  alias NotSpotify.Media.Events
  alias NotSpotify.MusicBus
  alias NotSpotify.Accounts.User

  def playing?(user) do
    start_if_not_running(user)
    GenServer.call(process_name(user), :playing?)
  end

  def stopped?(user) do
    start_if_not_running(user)
    GenServer.call(process_name(user), :stopped?)
  end

  def active_song(user) do
    start_if_not_running(user)
    GenServer.call(process_name(user), :active_song)
  end

  defmodule State do
    defstruct song: nil, playing: false, song_queue: [], user: nil
  end

  def start(user) do
    DynamicSupervisor.start_child(
      NotSpotify.Media.Supervisor,
      %{
        id: {__MODULE__, user.email},
        start: {__MODULE__, :start_link, [user]},
        restart: :transient
      }
    )
  end

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: process_name(user))
  end

  def init(user) do
    MusicBus.join(User.process_name(user))
    {:ok, %State{user: user}}
  end

  def process_name(%User{} = user) do
    {:global, user.email}
  end

  def handle_info({Media, %Events.Play{song: song}}, state) do
    Process.send_after(self(), {:stop_song, song}, song.duration)
    {:noreply, %{state | song: song, playing: true}}
  end

  def handle_info({Media, %Events.Pause{}}, state) do
    {:noreply, %{state | playing: false}}
  end

  def handle_info({Media, %Events.Stop{}}, state) do
    {:noreply, %{state | song: nil, playing: false}}
  end

  def handle_info({:stop_song, song}, %State{song: song} = state) do
    {:noreply, %{state | song: nil, playing: false}}
  end

  def handle_info({:stop_song, _}, state) do
    {:noreply, state}
  end

  def handle_call(:playing?, _from, state) do
    {:reply, state.playing, state}
  end

  def handle_call(:stopped?, _from, state) do
    {:reply, state.song == nil, state}
  end

  def handle_call(:active_song, _from, state) do
    {:reply, state.song, state}
  end

  def start_if_not_running(email) do
    case :global.whereis_name(process_name(email)) do
      pid when is_pid(pid) ->
        :ok

      :undefined ->
        start(email)
    end
  end
end
