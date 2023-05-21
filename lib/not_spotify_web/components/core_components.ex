defmodule NotSpotifyWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use NotSpotifyWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import NotSpotifyWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :rest, :global

  slot :title
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"}
      {@rest}
    >
      <.focus_wrap id={"#{@id}-focus-wrap"}>
        <div
          class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
          aria-labelledby={"#{@id}-title"}
          aria-describedby={"#{@id}-description"}
          role="dialog"
          aria-modal="true"
          tabindex="0"
        >
          <div
            class="fixed inset-0 bg-brand-black bg-opacity-75 transition-opacity"
            aria-hidden="true"
          >
          </div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <div
            id={"#{@id}-container"}
            class={
              "#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-brand-grey rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-3xl sm:w-full sm:p-6"
            }
            phx-window-keydown={hide_modal(@on_cancel, @id)}
            phx-key="escape"
            phx-click-away={hide_modal(@on_cancel, @id)}
          >
            <%= if @patch do %>
              <.link patch={@patch} data-modal-return class="hidden"></.link>
            <% end %>
            <%= if @navigate do %>
              <.link navigate={@navigate} data-modal-return class="hidden"></.link>
            <% end %>
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex-shrink-0 flex items-center justify-center h-8 w-8 rounded-full bg-brand-grey sm:mx-0">
                <!-- Heroicon name: outline/plus -->
                <.icon
                  name={:information_circle}
                  outlined
                  class="h-6 w-6 text-brand-orange bg-brand-grey"
                />
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full mr-12">
                <h3 class="text-lg leading-6 font-medium text-brand-orange" id={"#{@id}-title"}>
                  <%= render_slot(@title) %>
                </h3>
                <div class="mt-2">
                  <p id={"#{@id}-content"} class="text-sm text-brand-orange">
                    <%= render_slot(@inner_block) %>
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <%= for confirm <- @confirm do %>
                <button
                  id={"#{@id}-confirm"}
                  class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-brand-orange text-base font-medium text-zinc-100 hover:bg-orange-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
                  phx-click={@on_confirm}
                  phx-disable-with
                  {assigns_to_attributes(confirm)}
                >
                  <%= render_slot(confirm) %>
                </button>
              <% end %>
              <%= for cancel <- @cancel do %>
                <button
                  class="mt-3 w-full inline-flex justify-center rounded-md bg-brand-black shadow-sm px-4 py-2 text-base font-medium text-brand-orange hover:text-zinc-100 hover:bg-brand-orange focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
                  phx-click={hide_modal(@on_cancel, @id)}
                  {assigns_to_attributes(cancel)}
                >
                  <%= render_slot(cancel) %>
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr :flash, :map
  attr :kind, :atom

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class="rounded-md bg-red-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={
        JS.push("lv:clear-flash")
        |> JS.remove_class("fade-in-scale", to: "#flash")
        |> hide("#flash")
      }
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-red-700">
        <.icon name={:exclamation_circle} class="w-5 w-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600"
        >
          <.icon name={:x} class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in-scale") |> hide("#flash")}
      phx-value-key="info"
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-green-700">
        <.icon name={:check_circle} class="w-5 h-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600"
        >
          <.icon name={:x} class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-brand-grey">
        <%= render_slot(@inner_block, f) %>
        <div
          :for={action <- @actions}
          class="mt-2 flex items-center justify-between gap-6 text-brand-orange"
        >
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def three_elements_per_row_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 bg-brand-grey grid grid-cols-3">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 items-center text-brand-orange pt-0 flex mx-4">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :query, :string, required: true, doc: "the query to search for"

  attr :class, :string, default: nil, doc: "the class to apply to the form"

  def search_form(assigns) do
    ~H"""
    <form phx-submit="search" phx-change="search" phx-value-query={@query} class={@class}>
      <.input
        type="text"
        name="query"
        value={@query}
        placeholder="Search"
        class="text-sm text-zinc-100 placeholder-zinc-100 bg-brand-grey rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-orange focus:border-transparent my-auto"
      />
    </form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-brand-orange hover:bg-brand-black py-2 px-3",
        "text-sm font-semibold leading-6 text-zinc-100 hover:text-zinc-100 active:text-brand-black, border-zinc-100 border-1 border-brand-black",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-brand-orange">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-orange-600 text-brand-orange focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "min-h-[6rem] border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "block w-[98%] rounded-lg text-brand-orange focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-orange-600 phx-no-feedback:focus:border-brand-orange",
          "border-brand-orange focus:border-orange-600",
          "bg-brand-black",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-brand-orange">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  def error(%{errors: errors, field: field} = assigns) do
    assigns =
      assigns
      |> assign(:error_values, Keyword.get_values(errors, field))
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= for error <- @error_values do %>
      <span
        phx-feedback-for={@input_name}
        class={
          "invalid-feedback inline-block pl-2 pr-2 text-sm text-white bg-red-600 rounded-md #{@class}"
        }
      >
        <%= translate_error(error) %>
      </span>
    <% end %>
    <%= if Enum.empty?(@error_values) do %>
      <span class={"invalid-feedback inline-block h-0 #{@class}"}></span>
    <% end %>
    """
  end

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      - <%= render_slot(@inner_block) %> -
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-brand-orange">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-brand-orange">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :sorting, :any, default: nil, doc: "how to sort the rows"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :name, :string
    attr :hidden, :boolean
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="table-auto px-4 overflow-y-visible md:overflow-visible sm:px-2 m:w-full">
      <table class="w-full mt-11">
        <thead class="text-sm text-left leading-6 text-brand-orange">
          <tr>
            <th
              :for={col <- @col}
              class={[
                "p-0 pr-6 pb-4 font-normal whitespace-nowrap",
                if(col[:hidden], do: "hidden md:table-cell", else: ""),
                col[:class]
              ]}
            >
              <%= if is_nil(@sorting) do %>
                <.live_component
                  module={NotSpotifyWeb.SortingComponent}
                  id={"sorting-by-#{col[:name]}"}
                  name={col[:name]}
                  label={col[:label]}
                  sorting={@sorting}
                />
              <% else %>
                <%= col[:label] %>
              <% end %>
            </th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update="replace"
          class="relative divide-y divide-brand-orange border-t border-brand-orange text-sm leading-6 text-zinc-100"
        >
          <tr
            :for={{row, row_num} <- Enum.with_index(@rows)}
            id={@row_id && @row_id.(row)}
            class="group"
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.({row, row_num})}
              class={[
                "relative p-0",
                @row_click && "hover:cursor-pointer",
                if(col[:hidden], do: "hidden md:table-cell", else: "")
              ]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-brand-orange sm:rounded-l-xl" />
                <span class={[
                  "relative",
                  i == 0 && "font-semibold text-zinc-100",
                  if(col[:hidden], do: "hidden md:table-cell", else: ""),
                  col[:class]
                ]}>
                  <%= render_slot(col, @row_item.({row, row_num})) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative md:w-14 p-0 ">
              <div class="relative py-4 text-right text-sm font-medium grid grid-rows-2 grid-cols-2 md:grid-rows-1 md:grid-cols-5 gap-y-2 gap-x-3 md:gap-7">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-brand-orange sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative font-semibold leading-6 fill-zinc-100 hover:fill-zinc-300 c-span-1"
                >
                  <%= render_slot(action, @row_item.({row, row_num})) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14 min-w-[50%] ">
      <dl class="-my-4 divide-y divide-brand-orange">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8 justify-between">
          <dt class="w-1/4 flex-none text-orange-600 text-bold"><%= item.title %></dt>
          <dd class="text-brand-orange break-all"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.button>
          <!-- <.icon name={"hero-arrow-left-solid"} class="h-3 w-3" /> -->
          <%= render_slot(@inner_block) %>
        </.button>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :atom, required: true
  attr :outlined, :boolean, default: false
  attr :rest, :global, default: %{class: "w-4 h-4 inline-block"}

  def icon(assigns) do
    assigns = assign_new(assigns, :"aria-hidden", fn -> !Map.has_key?(assigns, :"aria-label") end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [Map.to_list(@rest)]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [Map.to_list(@rest)]) %>
    <% end %>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(NotSpotifyWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(NotSpotifyWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def home_path(), do: "/"

  attr :min, :integer, default: 0
  attr :max, :integer, default: 100
  attr :id, :string, default: "progress-bar"
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false

  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> assigns[:min] || 0 end)

    ~H"""
    <div
      id={"#{@id}-container"}
      class={"flex-auto rounded-full overflow-hidden bg-brand-black max-h-1.5 #{@class}"}
      phx-update="ignore"
    >
      <div
        id={@id}
        class="bg-brand-orange h-1.5 w-0"
        data-min={@min}
        data-max={@max}
        data-val={@value}
      >
      </div>
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <svg
      class="inline-block animate-spin h-2.5 w-2.5 text-gray-400"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  def translate_changeset_errors(changeset) do
    Enum.map_join(changeset.errors, "\n", fn {key, value} ->
      "#{key} #{translate_error(value)}"
    end)
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.

      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  def formatted_length(length) do
    "#{div(length, 60)}:#{formatted_seconds(rem(length, 60))}"
  end

  defp formatted_seconds(s) when s < 10, do: "0#{s}"
  defp formatted_seconds(s), do: "#{s}"
end
