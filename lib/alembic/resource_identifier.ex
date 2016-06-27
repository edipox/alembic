defmodule Alembic.ResourceIdentifier do
  @moduledoc """
  A [JSON API Resource Identifier](http://jsonapi.org/format/#document-resource-identifier-objects).
  """

  alias Alembic.Meta
  alias Alembic.Relationships
  alias Alembic.Resource
  alias Alembic.ToParams

  @behaviour ToParams

  # Constants

  @human_type "resource identifier"

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  },
                  parent: nil
                }

  # Struct

  defstruct [:id, :meta, :type]

  # Types

  @typedoc """
  > A "resource identifier object" is \\[an `%Alembic.ResourceIdentifier{}`\\] that identifies an
  > individual resource.
  >
  > A "resource identifier object" **MUST** contain `type` and `id` members.
  >
  > A "resource identifier object" **MAY** also include a `meta` member, whose value is a
  > \\[`Alembic.Meta.t`\\] that contains non-standard meta-information.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Identifier
  >   Object](http://jsonapi.org/format/#document-resource-identifier-objects)
  > </cite>
  """
  @type t :: %__MODULE__{
               id: String.t,
               meta: Meta.t,
               type: String.t
             }

  # Functions

  @doc """
  Converts `resource_identifier` to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  `id` and `type` will be used to lookup the attributes in `resource_by_id_by_type`.  Theses attributes and the id
  will be combined into a map for params

      iex> Alembic.ResourceIdentifier.to_params(
      ...>   %Alembic.ResourceIdentifier{id: "1", type: "author"},
      ...>   %{
      ...>     "author" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "author",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "name" => "Alice"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      %{
        "id" => "1",
        "name" => "Alice"
      }

  If no entry is found in `resource_by_id_by_type`, then only the `id` is copied to the params.  This can happen when
  the server only wants to send foreign keys.

      iex> Alembic.ResourceIdentifier.to_params(
      ...>   %Alembic.ResourceIdentifier{id: "1", type: "author"},
      ...>   %{}
      ...> )
      %{
        "id" => "1"
      }

  """
  @spec to_params(t, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(resource_identifier, resource_by_id_by_type) do
    to_params(resource_identifier, resource_by_id_by_type, %{})
  end

  @spec to_params(t, ToParams.resource_by_id_by_type, ToParams.converted_by_id_by_type) :: ToParams.params
  def to_params(%__MODULE__{id: id, type: type}, resource_by_id_by_type, converted_by_id_by_type) do
    case get_in(resource_by_id_by_type, [type, id]) do
      %Resource{type: ^type, id: ^id, attributes: attributes, relationships: relationships} ->
        case get_in(converted_by_id_by_type, [type, id]) do
          true ->
            %{"id" => id}
          nil ->
            updated_converted_by_id_by_type = converted_by_id_by_type
                                              |> Map.put_new(type, %{})
                                              |> put_in([type, id], true)

            attributes
            |> Map.put("id", id)
            |> Map.merge(
                 Relationships.to_params(relationships, resource_by_id_by_type, updated_converted_by_id_by_type)
               )
        end
      nil ->
        %{"id" => id}
    end
  end
end
