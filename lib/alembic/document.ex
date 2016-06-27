defmodule Alembic.Document do
  @moduledoc """
  JSON API refers to the top-level JSON structure as a [document](http://jsonapi.org/format/#document-structure).
  """

  alias Alembic.Resource
  alias Alembic.ResourceLinkage
  alias Alembic.ToParams

  # Behaviours

  @behaviour ToParams

  # Constants

  @data_options %{
                  field: :data,
                  member: %{
                    module: ResourceLinkage,
                    name: "data"
                  }
                }

  @errors_options %{
                    field: :errors,
                    member: %{
                      name: "errors"
                    }
                  }

  @included_options %{
                      field: :included,
                      member: %{
                        name: "included"
                      }
                    }

  @human_type "document"

  @minimum_children ~w{data errors meta}

  # DOES NOT include `@errors_options` because `&FromJson.from_json_array(&1, &2, Error)` cannot appear in a module
  #   attribute used in a function
  # DOES NOT include `@included_options` because `&FromJson.from_json_array(&1, &2, Resource)` cannot appear in a module
  #   attribute used in a function
  @child_options_list [
    @data_options
  ]

  # Struct

  defstruct data: :unset,
            errors: nil,
            included: nil,
            jsonapi: nil,
            links: nil,
            meta: nil

  # Types

  @typedoc """
  A JSON API [Document](http://jsonapi.org/format/#document-structure).

  ## Data

  When there are no errors, `data` are returned in the document and `errors` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Included                   |
  | `errors`   | Excluded                   |
  | `included` | Optional                   |
  | `links`    | Optional                   |
  | `meta`     | Optional                   |

  ## Errors

  When an error occurs, `errors` are returned in the document and `data` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Excluded                   |
  | `errors`   | Included                   |
  | `included` | Excluded                   |
  | `links`    | Optional                   |
  | `meta`     | Optional                   |

  ## Meta

  JSON API allows a `meta` only document, in which case `data` and `errors` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Excluded                   |
  | `errors`   | Excluded                   |
  | `included` | Excluded                   |
  | `links`    | Optional                   |
  | `meta`     | Included                   |

  """
  @type t :: %__MODULE__{
               data: nil,
               errors: list,
               included: nil,
               links: map | nil,
               meta: map | nil
             } |
             %__MODULE__{
               data: nil,
               errors: nil,
               included: nil,
               links: map | nil,
               meta: map
             } |
             %__MODULE__{
               data: [Resource.t] | Resource.t,
               errors: nil,
               included: [Resource.t] | nil,
               links: map | nil,
               meta: map | nil
             }

  # Functions

  @doc """
  Lookup table of `included` resources, so that `Alembic.ResourceIdentifier.t` can be
  converted to full `Alembic.Resource.t`.
  """
  @spec included_resource_by_id_by_type(t) :: ToParams.resource_by_id_by_type

  def included_resource_by_id_by_type(%__MODULE__{included: nil}), do: %{}

  def included_resource_by_id_by_type(%__MODULE__{included: included}) do
    Enum.reduce(
      included,
      %{},
      fn (resource = %Resource{id: id, type: type}, resource_by_id_by_type) ->
        resource_by_id_by_type
        |> Map.put_new(type, %{})
        |> put_in([type, id], resource)
      end
    )
  end

  @doc """
  Merges the errors from two documents together.

  The errors from the second document are prepended to the errors of the first document so that the errors as a whole
  can be reversed with `reverse/1`
  """
  def merge(first, second)

  @spec merge(%__MODULE__{errors: list}, %__MODULE__{errors: list}) :: %__MODULE__{errors: list}
  def merge(%__MODULE__{errors: first_errors}, %__MODULE__{errors: second_errors}) when is_list(first_errors) and
                                                                                        is_list(second_errors) do
    %__MODULE__{
      # Don't use Enum.into as it will reverse the list immediately, which is more reversing that necessary since
      # merge is called a bunch of time in sequence.
      errors: Enum.reduce(second_errors, first_errors, fn (second_error, acc_errors) ->
        [second_error | acc_errors]
      end)
    }
  end

  @doc """
  Since `merge/2` adds the second `errors` to the beginning of a `first` document's `errors` list, the final merged
  `errors` needs to be reversed to maintain the original order.
  """
  def reverse(document = %__MODULE__{errors: errors}) when is_list(errors) do
    %__MODULE__{document | errors: Enum.reverse(errors)}
  end

  @doc """
  Transforms a `t` into the nested params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## No resource

  No resource is transformed to an empty map

  ## Single resource

  A single resource is converted to a params map that combines the id and attributes.

  ### Relationships

  Relationships are merged into the params for the resource

  ## Multiple resources

  Multiple resources are converted to a params list where each element is a map that combines the id and attributes

  ### Relationships

  Relationships are merged into the params for the corresponding resource

  """
  @spec to_params(t) :: [map] | map
  def to_params(document = %__MODULE__{}) do
    resource_by_id_by_type = included_resource_by_id_by_type(document)
    to_params(document, resource_by_id_by_type, %{})
  end

  @doc """
  Transforms a `t` into the nested params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) using the given
  `resources_by_id_by_type`.

  See `Alembic.Document.to_params/1`
  """
  @spec to_params(%__MODULE__{data: [Resource.t] | Resource.t | nil},
                  ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(document, resource_by_id_by_type), do: to_params(document, resource_by_id_by_type, %{})

  @doc """
  Transforms a `t` into the nested params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) using the given
  `resources_by_id_by_type` and `converted_by_id_by_type`.

  See `InterpreterServer.Api.Document.to_params/1`
  """
  @spec to_params(%__MODULE__{data: [Resource.t] | Resource.t | nil},
                  ToParams.resource_by_id_by_type,
                  ToParams.converted_by_id_by_type) :: ToParams.params
  def to_params(%__MODULE__{data: data}, resource_by_id_by_type, converted_by_id_by_type) when is_list(data) do
    Enum.map(data, &Resource.to_params(&1, resource_by_id_by_type, converted_by_id_by_type))
  end

  def to_params(%__MODULE__{data: resource = %Resource{}}, resource_by_id_by_type, converted_by_id_by_type) do
    Resource.to_params(resource, resource_by_id_by_type, converted_by_id_by_type)
  end

  def to_params(%__MODULE__{data: nil}, _, _), do: %{}
end
