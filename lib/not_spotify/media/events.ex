defmodule NotSpotify.Media.Events do
  defmodule Play do
    defstruct song: nil, elapsed: nil
  end

  defmodule Pause do
    defstruct song: nil
  end
end
