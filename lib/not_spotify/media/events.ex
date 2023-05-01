defmodule NotSpotify.Media.Events do
  @moduledoc """
  The Media Event types.
  """

  defmodule Play do
    @moduledoc false
    defstruct song: nil, elapsed: nil
  end

  defmodule Pause do
    @moduledoc false
    defstruct song: nil, paused_at: nil
  end

  defmodule Stop do
    @moduledoc false
    defstruct song: nil
  end

  defmodule Next do
    @moduledoc false
    defstruct song: nil
  end

  defmodule Prev do
    @moduledoc false
    defstruct song: nil
  end
end
