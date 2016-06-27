defmodule Alembic.ResourceLinkage do
  @moduledoc """
  > Resource linkage in a compound document allows a client to link together all of the included resource objects
  > without having to `GET` any URLs via links.
  >
  > Resource linkage **MUST** be represented as one of the following:

  > * `null` for empty to-one relationships.
  > * an empty array (`[]`) for empty to-many relationships.
  > * a single resource identifier object for non-empty to-one relationships.
  > * an array of resource identifier objects for non-empty to-many relationships.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Resource Linkage](http://jsonapi.org/format/#document-resource-object-linkage)
  > </cite>
  """

  alias Alembic.Resource
  alias Alembic.ResourceIdentifier
  alias Alembic.ToParams

  @behaviour ToParams

  # Constants

  @human_type "resource linkage"

  # Functions

  @doc """
  Converts resource linkage to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## To-one

  An empty to-one, `nil`, is `nil` when converted to params.

      iex> Alembic.ResourceLinkage.to_params(nil, %{})
      nil

  A resource identifier uses `resource_by_id_by_type` to fill in the attributes of the referenced resource. `type` is
  dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types in the
  params.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   %Alembic.ResourceIdentifier{
      ...>     type: "shirt",
      ...>     id: "1"
      ...>   },
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      %{
        "id" => "1",
        "size" => "L"
      }

  On create or update, a relationship can be created by having an `Alembic.Resource.t`, in which case the
  attributes are supplied by the `Alembic.Resource.t`, instead of `resource_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   %Alembic.Resource{
      ...>     attributes: %{
      ...>       "size" => "L"
      ...>     },
      ...>     type: "shirt"
      ...>   },
      ...>   %{}
      ...> )
      %{
        "size" => "L"
      }

  ## To-many

  An empty to-many, `[]`, is `[]` when converted to params

      iex> Alembic.ResourceLinkage.to_params([], %{})
      []

  A list of resource identifiers uses `attributes_by_id_by_type` to fill in the attributes of the referenced resources.
  `type` is dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types
  in the params.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   [
      ...>     %Alembic.ResourceIdentifier{
      ...>       type: "shirt",
      ...>       id: "1"
      ...>     }
      ...>   ],
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>  }
      ...> )
      [
        %{
          "id" => "1",
          "size" => "L"
        }
      ]

  On create or update, a relationship can be created by having an `Alembic.Resource`, in which case the
  attributes are supplied by the `Alembic.Resource`, instead of `attributes_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   [
      ...>     %Alembic.Resource{
      ...>       attributes: %{
      ...>         "size" => "L"
      ...>       },
      ...>       type: "shirt"
      ...>     }
      ...>   ],
      ...>   %{}
      ...> )
      [
        %{
          "size" => "L"
        }
      ]

  """
  @spec to_params([Resource.t | ResourceIdentifier.t] | Resource.t | ResourceIdentifier.t | nil,
                  ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(resource_linkage, resource_by_id_by_type), do: to_params(resource_linkage, resource_by_id_by_type, %{})

  @spec to_params([Resource.t | ResourceIdentifier.t] | Resource.t | ResourceIdentifier.t | nil,
                  ToParams.resource_by_id_by_type,
                  ToParams.converted_by_id_by_type) :: ToParams.params

  def to_params(nil, %{}, %{}), do: nil

  def to_params(list, resource_by_id_by_type, converted_by_id_by_type) when is_list(list) do
    Enum.map list, &to_params(&1, resource_by_id_by_type, converted_by_id_by_type)
  end

  def to_params(resource = %Resource{}, resource_by_id_by_type, converted_by_id_by_type) do
    Resource.to_params(resource, resource_by_id_by_type, converted_by_id_by_type)
  end

  def to_params(resource_identifier = %ResourceIdentifier{}, resource_by_id_by_type, converted_by_id_by_type) do
    ResourceIdentifier.to_params(resource_identifier, resource_by_id_by_type, converted_by_id_by_type)
  end
end
