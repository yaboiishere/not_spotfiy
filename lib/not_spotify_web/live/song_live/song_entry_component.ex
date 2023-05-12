defmodule NotSpotifyWeb.SongLive.SongEntryComponent do
  use NotSpotifyWeb, :live_component

  alias NotSpotify.MP3Stat

  def send_progress(%Phoenix.LiveView.UploadEntry{} = entry) do
    send_update(__MODULE__, id: entry.ref, progress: entry.progress)
  end

  def render(assigns) do
    ~H"""
    <div class="sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start sm:border-t sm:border-brand-orange sm:pt-2 text-brand-orange">
      <div class="rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 ">
        <label for="name" class="block text-xs font-medium">
          <%= if @duration do %>
            Title <span class="text-brand-orange">(<%= MP3Stat.to_mmss(@duration) %>)</span>
          <% else %>
            Title
            <span class="text-brand-orange">
              (calculating duration
              <.spinner class="inline-block animate-spin h-2.5 w-2.5 text-brand-orange" />)
            </span>
          <% end %>
        </label>
        <input
          type="text"
          name={"songs[#{@ref}][title]"}
          value={@title}
          class="mt-2 block w-[98%] rounded-lg text-brand-orange focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-orange-600 phx-no-feedback:focus:border-brand-orange border-brand-orange focus:border-orange-600 bg-brand-black"
          {%{autofocus: @index == 0}}
        />
      </div>
      <div class="rounded-md px-3 py-2 mt-2 shadow-sm">
        <label for="name" class="block text-xs font-medium text-brand-orange">Artist</label>
        <input
          type="text"
          name={"songs[#{@ref}][artist]"}
          value={@artist}
          class="mt-2 block w-[98%] rounded-lg text-brand-orange focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-orange-600 phx-no-feedback:focus:border-brand-orange border-brand-orange focus:border-orange-600 bg-brand-black"
        />
      </div>
      <div class="col-span-full sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start">
        <.error input_name={"songs[#{@ref}][title]"} field={:title} errors={@errors} class="-mt-1" />
        <.error input_name={"songs[#{@ref}][artist]"} field={:artist} errors={@errors} class="-mt-1" />
      </div>
      <div
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@progress}
        style={"transition: width 0.5s ease-in-out; width: #{@progress}%; min-width: 1px;"}
        class="col-span-full bg-brand-orange h-1.5 w-0 p-0 rounded-lg mt-2"
      >
      </div>
    </div>
    """
  end

  def update(%{progress: progress}, socket) do
    {:ok, assign(socket, progress: progress)}
  end

  def update(%{changeset: changeset, id: id, index: index}, socket) do
    {:ok,
     socket
     |> assign(ref: id)
     |> assign(index: index)
     |> assign(:errors, changeset.errors)
     |> assign(title: Ecto.Changeset.get_field(changeset, :title))
     |> assign(artist: Ecto.Changeset.get_field(changeset, :artist))
     |> assign(duration: Ecto.Changeset.get_field(changeset, :duration))
     |> assign_new(:progress, fn -> 0 end)}
  end
end
