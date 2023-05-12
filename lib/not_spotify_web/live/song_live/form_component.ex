defmodule NotSpotifyWeb.SongLive.FormComponent do
  use NotSpotifyWeb, :live_component

  alias NotSpotify.Media

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-brand-grey">
      <.header>
        <%= @title %>
        <:subtitle>Edit Song</:subtitle>
      </.header>

      <.three_elements_per_row_form
        for={@form}
        id="song-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Song title" />
        <.input field={@form[:artist]} type="text" label="Song artist" />
        <.input field={@form[:album]} type="text" label="Song album" />
        <.input field={@form[:album_artist]} type="text" label="Album artist" />
        <.input field={@form[:genre]} type="text" label="Song genre" />
        <.input field={@form[:date_recorded]} type="number" label="Date recorded" />
        <.input field={@form[:date_released]} type="number" label="Date released" />
        <.input field={@form[:track]} type="text" label="Genre" />
        <.input field={@form[:genre]} type="text" label="Song genre" />
        <div></div>

        <:actions>
          <.button class="mx-auto" phx-disable-with="Saving...">Save Song</.button>
        </:actions>
      </.three_elements_per_row_form>
    </div>
    """
  end

  @impl true
  def update(%{song: song} = assigns, socket) do
    changeset = Media.change_song(song)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"song" => song_params}, socket) do
    changeset =
      socket.assigns.song
      |> Media.change_song(song_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event(
        "save",
        %{"song" => song_params},
        %{
          assigns: %{action: action, current_user: current_user}
        } = socket
      ) do
    song_params = Map.put(song_params, "artist_id", current_user.id)

    save_song(socket, action, song_params)
  end

  defp save_song(socket, :edit, song_params) do
    case Media.update_song(socket.assigns.song, song_params) do
      {:ok, song} ->
        notify_parent({:saved, song})

        {:noreply,
         socket
         |> put_flash(:info, "Song updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_song(socket, :new, song_params) do
    case Media.create_song(song_params) do
      {:ok, song} ->
        notify_parent({:saved, song})

        {:noreply,
         socket
         |> put_flash(:info, "Song created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
