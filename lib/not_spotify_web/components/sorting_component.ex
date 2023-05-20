defmodule NotSpotifyWeb.SortingComponent do
  @moduledoc """
  Live component that provides sorting functionality.
  """

  use NotSpotifyWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      phx-click="sort_by_column"
      phx-target={@myself}
      phx-value-column={@name}
      class="sorting-header hover:cursor-pointer hover:text-orange-600"
    >
      <%= @label %> <%= chevron(
        @sorting,
        maybe_to_atom(@name)
      ) %>
    </div>
    """
  end

  def handle_event("sort_by_column", %{"column" => selected_column}, socket) do
    %{sorting: %{sort_dir: sort_dir, sort_by: column}} = socket.assigns

    sort_dir =
      case {sort_dir, String.to_atom(selected_column)} do
        {:asc, ^column} -> :desc
        {:desc, ^column} -> :asc
        _ -> :desc
      end

    new_sorting = %{sort_by: selected_column, sort_dir: sort_dir}

    send(self(), {:update, new_sorting})
    {:noreply, socket}
  end

  def chevron(%{sort_by: sort_by, sort_dir: :asc}, sort_by), do: "⇧"
  def chevron(%{sort_by: sort_by, sort_dir: :desc}, sort_by), do: "⇩"
  def chevron(_opts, _column), do: ""

  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)
  defp maybe_to_atom(value), do: value
end
