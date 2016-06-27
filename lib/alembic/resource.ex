defmodule Alembic.Resource do
  # Types

  @type t :: %{type: String.t}

  # Functions

  @spec to_map(t) :: map
  def to_map(resource), do: to_map(resource, %{})

  @spec to_map(t, map) :: map
  def to_map(_, map) when is_map(map), do: %{}
end
