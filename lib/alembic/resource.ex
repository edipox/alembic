defmodule Alembic.Resource do
  @moduledoc """
  The individual JSON object of elements of the list of the `data` member of the
  [JSON API document](http://jsonapi.org/format/#document-structure) are
  [resources](http://jsonapi.org/format/#document-resource-objects) as are the members of the `included` member.
  """

  alias Alembic.ToParams

  @behaviour ToParams

  # Constants

  @attributes_human_type "json object"

  @attributes_options %{
                        field: :attributes,
                        member: %{
                          name: "attributes"
                        }
                      }

  @id_options %{
                field: :id,
                member: %{
                  from_json: &FromJson.string_from_json/2,
                  name: "id"
                }
              }

  @type_options %{
                  field: :type,
                  member: %{
                    from_json: &FromJson.string_from_json/2,
                    name: "type",
                    required: true
                  }
                }

  # DOES NOT include `@attribute_options` because it needs to be customized with private function reference
  # DOES NOT include `@id_options` because it needs to be customized based on `error_template.meta`
  @child_options_list [
    @type_options
  ]

  @human_type "resource"

  # Struct

  defstruct attributes: nil,
            id: nil,
            links: nil,
            meta: nil,
            relationships: nil,
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

  @typedoc """
  Resource objects" appear in a JSON API document to represent resources.

  A resource object **MUST** contain at least the following top-level members:

  * `id`
  * `type`

  Exception: The `id` member is not required when the resource object originates at the client and represents a new
  resource to be created on the server. (`%{action: :create, source: :client}`)

  In addition, a resource object **MAY(( contain any of these top-level members:

  * `attributes` - an [attributes object](http://jsonapi.org/format/#document-resource-object-attributes) representing
    some of the resource's data.
  * `links` - a `String.t` or `map` containing links related to the resource.
  * `meta` - contains non-standard meta-information about a resource that can not be represented as an attribute or
    relationship.
  * `relationships` - a [relationships object](http://jsonapi.org/format/#document-resource-object-relationships)
    describing relationships between the resource and other JSON API resources.
  """
  @type t :: %__MODULE__{
               attributes: Alembic.json_object | nil,
               id: id | nil,
               links: map | nil,
               meta: map | nil,
               relationships: map | nil,
               type: type
             }

  # Functions

  @doc """
  Converts `resource` to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).
  The `id` and `attributes` are combined into a single map for params.

      iex> Alembic.Resource.to_params(
      ...>   %Alembic.Resource{
      ...>     attributes: %{"text" => "First!"},
      ...>     id: "1",
      ...>     type: "post"
      ...>   },
      ...>   %{}
      ...> )
      %{
        "id" => "1",
        "text" => "First!"
      }

  But, `id` won't show up as "id" in params if it is `nil`

      iex> Alembic.Resource.to_params(
      ...>   %Alembic.Resource{
      ...>     attributes: %{"text" => "First!"},
      ...>     type: "post"
      ...>   },
      ...>   %{}
      ...> )
      %{
        "text" => "First!"
      }

  ## Relationships

  Relationships's params are merged into the `resource`'s params

  """
  @spec to_params(t, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(resource, resource_by_id_by_type), do: to_params(resource, resource_by_id_by_type, %{})

  @spec to_params(t, ToParams.resource_by_id_by_type, ToParams.converted_by_id_by_type) :: ToParams.params
  def to_params(resource, resource_by_id_by_type, converted_by_id_by_type)

  def to_params(%__MODULE__{attributes: attributes, id: id, relationships: _, type: type},
                resource_by_id_by_type,
                converted_by_id_by_type) when is_map(resource_by_id_by_type) and is_map(converted_by_id_by_type) do
    case get_in(converted_by_id_by_type, [type, id]) do
      true ->
        %{"id" => id}
      nil ->
        params = attributes || %{}

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
