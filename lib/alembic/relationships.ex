defmodule Alembic.Relationships do
  @moduledoc """
  > The value of the `relationships` key MUST be an object (a "relationships object"). Members of the relationships
  > object ("relationships") represent references from the resource object in which it's defined to other resource
  > objects.
  >
  > Relationships may be to-one or to-many.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-object-relationships)
  > </cite>
  """

  alias Alembic.Relationship
  alias Alembic.ToParams

  @behaviour ToParams

  # Constants

  @human_type "relationships object"

  # Types

  @type relationship :: Alembic.json_object

  @typedoc """
  Maps `String.t` name to `relationship`
  """
  @type t :: %{String.t => relationship}

  # Functions

  @doc """
  Converts relationships to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) that can be merged with the params
  from the primary data.

  ## No relationships

  No relationships are represented as `nil` in `Alembic.Document.t`, but since the output of
  `to_params/2` is expected to be `Map.merge/2` with the primary resource's params, an empty map is returned when
  relationships is `nil`.

      iex> Alembic.Relationships.to_params(nil, %{})
      %{}

  ## Some Relationships

  Relatonship params are expected to be `Map.merge/2` with the primary resource's params, so a relationships are
  returned as a map using the original relationship name and each `Alembic.Relationship.t` converted with
  `Alembic.Relationship.to_params/2`.

  ### Resource Identifiers

  If the resource linkage for a relationship is an `Alembic.ResourceIdentifier.t`, then the attributes for
  the resource will be looked up in `resource_by_id_by_type`.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
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
        "author" => %{
          "id" => "1",
          "name" => "Alice"
        }
      }

  Resources are not required to be in `resources_by_id_by_type`, as would be the case when only a foreign key is
  supplied.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "author" => %{
          "id" => "1"
        }
      }

  ### Resources

  On create or update, the relationships can directly contain `Alembic.Resource.t` that are to be created,
  in which case the `resource_by_id_by_type` are ignored.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.Resource{
      ...>         attributes: %{"name" => "Alice"},
      ...>         type: "author"
      ...>       }
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "author" => %{
          "name" => "Alice"
        }
      }

  ### Not Included

  If a relationship is not included, then no linkage `data` may be present and `{:error, :unset}` will be returned
  from `Alembic.Relationshio.to_params/3`.  For those relationships, they will not appear in the params
  of all relationships.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.Resource{
      ...>         attributes: %{"name" => "Alice"},
      ...>         type: "author"
      ...>       }
      ...>     },
      ...>     "comments" => %Alembic.Relationship{
      ...>       links: %{
      ...>         "related" => "https://example.com/api/v1/posts/1/comments"
      ...>       }
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "author" => %{
          "name" => "Alice"
        }
      }

  """
  @spec to_params(nil, ToParams.resource_by_id_by_type) :: %{}
  @spec to_params(t, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(relationship_by_name, resource_by_id_by_type) do
    to_params(relationship_by_name, resource_by_id_by_type, %{})
  end

  @spec to_params(nil, ToParams.resource_by_id_by_type, ToParams.converted_by_id_by_type) :: %{}
  def to_params(nil, _, _), do: %{}

  @spec to_params(t, ToParams.resource_by_id_by_type, ToParams.converted_by_id_by_type) :: ToParams.params
  def to_params(relationship_by_name = %{}, resource_by_id_by_type = %{}, converted_by_id_by_type) do
    Enum.reduce relationship_by_name, %{}, fn {name, relationship}, acc ->
      case Relationship.to_params(relationship, resource_by_id_by_type, converted_by_id_by_type) do
        {:error, :unset} ->
          acc
        relationship_params ->
          Map.put(acc, name, relationship_params)
      end
    end
  end
end
