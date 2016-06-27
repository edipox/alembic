defmodule Alembic.Resource do
  # Struct

  defstruct type: nil

  # Types

  @type type :: String.t

  @type t :: %__MODULE__{
               type: type
             }

  # Functions

  @spec to_map(t) :: map
  def to_map(resource), do: to_map(resource, %{})

  @spec to_map(t, map) :: map
  def to_map(_, map) when is_map(map), do: %{}
end
