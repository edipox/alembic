defmodule Alembic.ToParams do
  @moduledoc """
  The `Alembic.ToParams` behaviour converts a data structure in the `Alembic` namespace to
  the params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).
  """

  # Types

  @typedoc """
  A nested map with the outer layer keyed by the `Alembic.Resource.type`, then the next layer keys by the
  `Alembic.Resource.id` with the values not being present initially, but being updated to `true` once the
  `{type, id}` is converted once.
  """
  @type converted_by_id_by_type :: %{Resource.type => %{Resource.id => boolean}}

  @typedoc """
  Params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).
  """
  @type params :: list | map | nil

  @typedoc """
  A nest map with the outer layer keyed by the `Alembic.Resource.type`, then the next layer keyed by the
  `Alembic.Resource.id` with the values being the full `Alembic.Resource.t`
  """
  @type resource_by_id_by_type :: %{Resource.type => %{Resource.id => Resource.t}}

  # Callbacks

  @doc """
  ## Parameters

  * `convertable` - an `Alembic.Document.t` hierarchy data structure
  * `resources_by_id_by_type` - A nest map with the outer layer keyed by the `Alembic.Resource.type`,
    then the next layer keyed by the `Alembic.Resource.id` with the values being the full
    `Alembic.Resource.t` from `Alembic.Document.t` `included`.

  ## Returns

  * `nil` if an empty singleton
  * `%{}` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[%{}]` - if a non-empty collection
  """
  @callback to_params(convertable :: any, resource_by_id_by_type) :: params

  @doc """
  Unlike `to_params/2`, if `type` and `id` of `convertable` already exists in `converted_by_id_by_type`, then the params
  returned are only `%{ "id" => id }` without any further expansion, that is, a resource identifier, so that loops are
  prevented.

  ## Parameters

  * `convertable` - an `Alembic.Document.t` hierarchy data structure
  * `resources_by_id_by_type` - A nest map with the outer layer keyed by the `Alembic.Resource.type`,
    then the next layer keyed by the `Alembic.Resource.id` with the values being the full
    `Alembic.Resource.t` from `Alembic.Document.t` `included`.
  * `converted_by_id_by_type` - Tracks which (type, id) have been converted already to prevent infinite recursion when
    expanding indirect relationships.

  ## Returns

  ### Success

  * `{nil}` if an empty singleton
  * `%{}` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[%{}]` - if a non-empty collection

  ### Errors

  * `{:error, :already_converted}` - if the `type` and `id` of `convertable` already exists in `converted_by_id_by_type`
  """
  @callback to_params(convertable :: any, resource_by_id_by_type, converted_by_id_by_type) :: params

  # Functions

  @doc """
  Converts nested parameters for `belongs_to` associations to a foreign key parameter.

      iex> Alembic.ToParams.nested_to_foreign_keys(
      ...>   %{
      ...>     "id" => 1,
      ...>     "author" => %{
      ...>       "id" => 2
      ...>     },
      ...>     "text" => "Welcome to my new blog!"
      ...>   },
      ...>   Alembic.TestPost
      ...> )
      %{
        "id" => 1,
        "author_id" => 2,
        "text" => "Welcome to my new blog!"
      }

  """
  @spec nested_to_foreign_keys(params, module) :: params
  def nested_to_foreign_keys(nested_params, schema_module) do
    :associations
    |> schema_module.__schema__
    |> Stream.map(&schema_module.__schema__(:association, &1))
    |> Enum.reduce(
         nested_params,
         &reduce_nested_association_params_to_foreign_keys/2
       )
  end

  ## Private Functions

  defp reduce_nested_association_params_to_foreign_keys(
         %Ecto.Association.BelongsTo{field: field, owner_key: owner_key, related_key: related_key},
         acc
       ) do
    param_name = to_string(field)

    case Map.fetch(acc, param_name) do
      {:ok, association_params} ->
        case Map.fetch(association_params, to_string(related_key)) do
          {:ok, foreign_key_value} ->
            foreign_key_param_name = to_string(owner_key)

            acc
            |> Map.delete(param_name)
            |> Map.put(foreign_key_param_name, foreign_key_value)
          :error ->
            acc
        end
      :error ->
        acc
    end
  end

  defp reduce_nested_association_params_to_foreign_keys(_, acc), do: acc
end
