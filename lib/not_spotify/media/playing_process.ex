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

  def song_queue(user) do
    start_if_not_running(user)
    GenServer.call(process_name(user), :song_queue)
  end

  defmodule State do
    defstruct song: nil, playing: false, song_queue: [], user: nil, history: []
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

  def handle_info({Media, %Events.Play{song: nil}}, state) do
    Process.send(self(), {Media, %Events.Stop{}}, [])
    {:noreply, state}
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

  def handle_info({Media, %Events.AddToQueue{song: song}}, state) do
    {:noreply, %{state | song_queue: [song | state.song_queue]}}
  end

  def handle_info({Media, %Events.Next{}}, %State{song_queue: []} = state) do
    {:noreply, state}
  end

  def handle_info({Media, %Events.Next{}}, %State{song: nil} = state) do
    Process.send(self(), {Media, %Events.Stop{}}, [])
    {:noreply, state}
  end

  def handle_info({Media, %Events.Next{}}, %State{song: song, song_queue: [next | rest], history: history} = state) do
    new_state = %State{state | song_queue: rest, history: [song | history] }
    Process.send(self(), {Media, %Events.Play{song: next}}, [])
    
    {:noreply, new_state}
  end

  def handle_info({Media, %Events.Prev{}}, %State{history: []} = state) do
    {:noreply, state}
  end

  def handle_info({Media, %Events.Prev{}}, %State{song: nil} = state) do
    Process.send(self(), {Media, %Events.Stop{}}, [])
    {:noreply, state}
  end

  def handle_info({Media, %Events.Prev{}}, %State{history: [prev | rest]} = state) do
    new_state = %State{state | song_queue: [prev | state.song_queue], history: rest}
    Process.send(self(), {Media, %Events.Play{song: prev}}, [])
    
    {:noreply, new_state}
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

  def handle_call(:song_queue, _from, state) do
    {:reply, state.song_queue, state}
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
