defmodule NotSpotifyWeb.SongLive.FormComponent do
  use NotSpotifyWeb, :live_component

  alias NotSpotify.Media

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage song records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="song-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:year]} type="number" label="Year" />
        <.input field={@form[:content_location]} type="text" label="Content location" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Song</.button>
        </:actions>
      </.simple_form>
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
