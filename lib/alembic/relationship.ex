defmodule Alembic.Relationship do
  @moduledoc """
  > Members of the relationships object ("relationships") represent references from the resource object in which it's
  > defined to other resource objects.
  >
  > Relationships may be to-one or to-many.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-objects-relationships)
  > </cite>
  """

  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.ResourceLinkage
  alias Alembic.ToParams

  @behaviour ToParams

  # Constants

  @data_options %{
                  field: :data,
                  member: %{
                    module: ResourceLinkage,
                    name: "data"
                  },
                  parent: nil
                }

  @human_type "relationship"

  @links_options %{
                   field: :links,
                   member: %{
                     module: Links,
                     name: "links"
                   },
                   parent: nil
                 }

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  },
                  parent: nil
                }
  # Struct

  defstruct data: :unset,
            links: nil,
            meta: nil

  # Types

  @typedoc """
  > A "relationship object" **MUST** contain at least one of the following:
  >
  > * `links` - a links object containing at least one of the following:
  >     * `self` - a link for the relationship itself (a "relationship link"). This link allows the client to directly
  >        manipulate the relationship. For example, removing an author through an article's relationship URL would
  >        disconnect the person from the article without deleting the people resource itself. When fetched
  >        successfully, this link returns the linkage for the related resources as its primary data. (See Fetching
  >        Relationships.)
  >     * `related` - a related resource link
  > * `data` - resource linkage
  > * `meta` - a meta object that contains non-standard meta-information about the relationship.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-objects-relationships)
  > </cite>
  """
  @type t :: %__MODULE__{
               data: [ResourceIdentifier.t] | ResourceIdentifier.t | nil | :unset,
               links: Links.links,
               meta: Meta.t
             }

  # Functions

  @doc """
  Converts `t` to params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## To-one

  An empty to-one, `nil`, is `nil` when converted to params.

      iex> Alembic.Relationship.to_params(%Alembic.Relationship{data: nil}, %{})
      nil

  A resource identifier uses `resource_by_id_by_type` to fill in the attributes of the referenced resource. `type` is
  dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types in the
  params.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: %Alembic.ResourceIdentifier{
      ...>       id: "1", type: "shirt"
      ...>     }
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

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: %Alembic.Resource{
      ...>       attributes: %{
      ...>         "size" => "L"
      ...>       },
      ...>       type: "shirt"
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "size" => "L"
      }

  ## To-many

  An empty to-many, `[]`, is `[]` when converted to params

      iex> Alembic.Relationship.to_params(%Alembic.Relationship{data: []}, %{})
      []

  A list of resource identifiers uses `resource_by_id_by_type` to fill in the attributes of the referenced resources.
  `type` is dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types
  in the params.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: [
      ...>       %Alembic.ResourceIdentifier{
      ...>         id: "1", type: "shirt"
      ...>       }
      ...>     ]
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
      ...>  }
      ...> )
      [
        %{
          "id" => "1",
          "size" => "L"
        }
      ]

  On create or update, a relationship can be created by having an `Alembic.Resource.t`, in which case the
  attributes are supplied by the `Alembic.Resource`, instead of `resource_by_id_by_type`.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: [
      ...>       %Alembic.Resource{
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         },
      ...>         type: "shirt"
      ...>       }
      ...>     ]
      ...>   },
      ...>   %{}
      ...> )
      [
        %{
          "size" => "L"
        }
      ]

  ## Not Included

  If a relationship is not included, then no linkage `data` may be present and `{:error, :unset}` will be returned

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: :unset
      ...>   },
      ...>   %{}
      ...> )
      {:error, :unset}

  """
  @spec to_params(%__MODULE__{data: any}, ToParams.resource_by_id_by_type) :: ToParams.params | {:error, :unset}
  def to_params(relationship, resource_by_id_by_type), do: to_params(relationship, resource_by_id_by_type, %{})

  @doc """
  Converts `t` to params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4),
  but unlike `to_params/2`, will skip converting data in `t` where the `type` and `id` are already in
  `converted_by_id_by_type`.
  """
  @spec to_params(%__MODULE__{data: any},
                  ToParams.resource_by_id_by_type,
                  ToParams.converted_by_id_by_type) :: ToParams.params | {:error, :already_converted | :unset}
  def to_params(relationship, resource_by_id_by_type, converted_by_id_by_type)

  def to_params(%__MODULE__{data: :unset}, _, _), do: {:error, :unset}

  def to_params(%__MODULE__{data: data}, resource_by_id_by_type, converted_by_id_by_type) do
    ResourceLinkage.to_params(data, resource_by_id_by_type, converted_by_id_by_type)
  end

  # Protocol Implementations

  defimpl Poison.Encoder do
    @doc """
    ## Data

    An `:unset` data is excluded from the JSON

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     data: :unset
        ...>   }
        ...> )
        {:ok, "{}"}

    ### To-One

    A `nil` data is encoded as `null` in the JSON, representing an empty to-one relationship

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     data: nil
        ...>   }
        ...> )
        {:ok, "{\\"data\\":null}"}

    A resource or resource identifier is encoded in the JSON, representing a present to-one relationhip

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     data: %Alembic.ResourceIdentifier{
        ...>       id: "1",
        ...>       type: "author"
        ...>     }
        ...>   }
        ...> )
        {:ok, "{\\"data\\":{\\"type\\":\\"author\\",\\"id\\":\\"1\\"}}"}

    ### To-Many

    An empty list, `[]` is encoded as an empty list `[]` in the JOSN, representing an empty to-many relationship

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     data: []
        ...>   }
        ...> )
        {:ok, "{\\"data\\":[]}"}

    An non-empty list of resources and/or resource identifiers is encoded as a list in the JSON, representing an present
    to-many relationship

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     data: [
        ...>       %Alembic.ResourceIdentifier{
        ...>         id: "1", type: "shirt"
        ...>       }
        ...>     ]
        ...>   }
        ...> )
        {:ok, "{\\"data\\":[{\\"type\\":\\"shirt\\",\\"id\\":\\"1\\"}]}"}

    ## Links

    `links` are not encoded when `nil`.

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     links: nil
        ...>   }
        ...> )
        {:ok, "{}"}

    `links` are encoded when present

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     links: %{
        ...>       "related" => "https://example.com/api/v1/posts/1/comments"
        ...>     }
        ...>   }
        ...> )
        {:ok, "{\\"links\\":{\\"related\\":\\"https://example.com/api/v1/posts/1/comments\\"}}"}

    ## Meta

    `meta` is not encoded when `nil`.

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     meta: nil
        ...>   }
        ...> )
        {:ok, "{}"}

    `meta` is encoded when present

        iex> Poison.encode(
        ...>   %Alembic.Relationship{
        ...>     meta: %{
        ...>       "version" => "1"
        ...>     }
        ...>   }
        ...> )
        {:ok, "{\\"meta\\":{\\"version\\":\\"1\\"}}"}

    """
    def encode(relationship = %@for{}, options) do
      map = for {field, value} <- Map.from_struct(relationship),
                (field == :data && value != :unset) || (field != :data && value != nil),
                into: %{},
                do: {field, value}

      Poison.Encoder.Map.encode(map, options)
    end
  end
end
