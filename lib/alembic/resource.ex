defmodule Alembic.Resource do
  alias Alembic.ToParams

  @behaviour ToParams

  # Struct

  defstruct id: nil,
             type: nil

  # Types

  @typedoc """
  The ID of a `Resource.t`.  Usually the primary key or UUID for a resource in the server.
  """
  @type id :: String.t

  @typedoc """
  The type of a `Resource.t`.  Can be either singular or pluralized, althought the JSON API spec examples favor
  pluralized.
  """
  @type type :: String.t

  @type t :: %__MODULE__{
               id: id | nil,
               type: type
             }

  # Functions

  @spec to_params(t, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(resource, resource_by_id_by_type), do: to_params(resource, resource_by_id_by_type, %{})

  @spec to_params(t, ToParams.resource_by_id_by_type, ToParams.converted_by_id_by_type) :: ToParams.params
  def to_params(resource, resource_by_id_by_type, converted_by_id_by_type)

  def to_params(%__MODULE__{id: id, type: type},
                resource_by_id_by_type,
                converted_by_id_by_type) when is_map(resource_by_id_by_type) and is_map(converted_by_id_by_type) do
    case get_in(converted_by_id_by_type, [type, id]) do
      true ->
        %{"id" => id}
      nil ->
        params = %{}

        params = case id do
          nil ->
            params
          _ ->
            Map.put(params, "id", id)
        end

        updated_converted_by_id_by_type = converted_by_id_by_type
                                          |> Map.put_new(type, %{})
                                          |> put_in([type, id], true)

        Map.merge(params, %{})
    end
  end
end
