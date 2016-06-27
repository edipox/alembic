defmodule Alembic.Resource do
  # Struct

  defstruct type: nil

  # Types

  @type type :: String.t

  @type t :: %__MODULE__{
               type: type
             }

  # Functions

  @spec to_params(t, map) :: map
  def to_params(resource, resource_by_id_by_type), do: to_params(resource, resource_by_id_by_type, %{})

  @spec to_params(t, map, map) :: map

  def to_params(_,
                resource_by_id_by_type,
                converted_by_id_by_type) when is_map(resource_by_id_by_type) and is_map(converted_by_id_by_type) do
    %{}
  end
end
