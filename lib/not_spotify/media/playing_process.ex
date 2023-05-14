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

  def set_volume(user, volume) do
    start_if_not_running(user)
    GenServer.cast(process_name(user), {:set_volume, volume})
  end

  def get_volume(user) do
    start_if_not_running(user)
    GenServer.call(process_name(user), :get_volume)
  end

  defmodule State do
    defstruct song: nil,
              playing: false,
              song_queue: [],
              user: nil,
              history: [],
              song_ref: nil,
              volume: 1
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
    Process.send(self(), {Media, Events.Stop}, [])
    {:noreply, state}
  end

  def handle_info({Media, %Events.Play{song: song}}, state) do
    ref = make_ref()
    Process.send_after(self(), {:stop_song, ref}, :timer.seconds(song.duration))
    {:noreply, %State{state | song: song, playing: true, song_ref: ref}}
  end

  def handle_info({Media, %Events.Pause{}}, state) do
    {:noreply, %State{state | playing: false}}
  end

  def handle_info({Media, Events.Stop}, state) do
    {:noreply, %{state | song: nil, playing: false}}
  end

  def handle_info({Media, %Events.AddToQueue{song: song}}, %State{song_queue: song_queue} = state) do
    {:noreply, %{state | song_queue: song_queue ++ [song]}}
  end

  def handle_info({Media, Events.Next}, %State{song_queue: [], user: user} = state) do
    broadcast_stop(user)
    {:noreply, state}
  end

  def handle_info({Media, Events.Next}, %State{song: nil, user: user} = state) do
    broadcast_stop(user)
    {:noreply, state}
  end

  def handle_info(
        {Media, Events.Next},
        %State{song: song, song_queue: [next | rest], history: history, user: user} = state
      ) do
    new_state = %State{state | song_queue: rest, history: [song | history], song: next}
    Process.send(self(), {Media, %Events.Play{song: next}}, [])
    MusicBus.broadcast(User.process_name(user), {Media, %Events.NextCallback{song: next}})

    {:noreply, new_state}
  end

  def handle_info({Media, Events.Prev}, %State{history: []} = state) do
    {:noreply, state}
  end

  def handle_info({Media, Events.Prev}, %State{song: nil} = state) do
    Process.send(self(), {Media, Events.Stop}, [])
    {:noreply, state}
  end

  def handle_info(
        {Media, Events.Prev},
        %State{history: [prev | rest], song_queue: song_queue, user: user, song: song} = state
      ) do
    new_state = %State{state | song_queue: [song | song_queue], history: rest, song: prev}
    Process.send(self(), {Media, %Events.Play{song: prev}}, [])
    MusicBus.broadcast(User.process_name(user), {Media, %Events.PrevCallback{song: prev}})

    {:noreply, new_state}
  end

  def handle_info({Media, %Events.NextCallback{}}, state) do
    {:noreply, state}
  end

  def handle_info({Media, %Events.PrevCallback{}}, state) do
    {:noreply, state}
  end

  def handle_info({Media, Events.ClearQueue}, state) do
    {:noreply, %{state | song_queue: []}}
  end

  def handle_info({:stop_song, ref}, %State{song_ref: ref} = state) do
    {:noreply, %{state | song: nil, playing: false}}
  end

  def handle_info({:stop_song, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:set_volume, volume}, state) do
    {:noreply, %{state | volume: volume}}
  end

  def handle_call(:get_volume, _from, %State{volume: volume} = state) do
    {:reply, volume, state}
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

  def broadcast_stop(user) do
    MusicBus.broadcast(User.process_name(user), {Media, Events.Stop})
  end
end
