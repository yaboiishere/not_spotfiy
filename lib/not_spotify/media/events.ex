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
    defstruct paused_at: nil
  end

  defmodule Stop do
    @moduledoc false
  end

  defmodule Next do
    @moduledoc false
  end

  defmodule Prev do
    @moduledoc false
  end

  defmodule NextCallback do
    @moduledoc false
    defstruct song: nil
  end

  defmodule PrevCallback do
    @moduledoc false
    defstruct song: nil
  end

  defmodule AddToQueue do
    @moduledoc false
    defstruct song: nil
  end

  defmodule ClearQueue do
    @moduledoc false
  end

  defmodule Seeked do
    @moduledoc false
    defstruct seeked: nil
  end
end
