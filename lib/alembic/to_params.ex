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

  ### Success

  * `nil` if an empty singleton
  * `%{}` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[%{}]` - if a non-empty collection

  ### Errors

  * `{:error, :unset}` - if the `convertable` data is not set
  """
  @callback to_params(convertable :: any, resource_by_id_by_type) :: params | {:error, :unset}

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
  * `{:error, :unset}` - if the `convertable` data is not set
  """
  @callback to_params(
              convertable :: any,
              resource_by_id_by_type,
              converted_by_id_by_type
            ) :: params | {:error, :already_converted | :unset}

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

  `nil` for the nested parameters converts to a `nil` foreign key parameter

      iex> Alembic.ToParams.nested_to_foreign_keys(
      ...>   %{
      ...>     "id" => 1,
      ...>     "author" => nil,
      ...>     "text" => "Welcome to my new blog!"
      ...>   },
      ...>   Alembic.TestPost
      ...> )
      %{
        "id" => 1,
        "author_id" => nil,
        "text" => "Welcome to my new blog!"
      }

  This differs from when the nested parameters are not even present, in which case the foreign key won't be added

      iex> Alembic.ToParams.nested_to_foreign_keys(
      ...>   %{
      ...>     "id" => 1,
      ...>     "text" => "Welcome to my new blog!"
      ...>   },
      ...>   Alembic.TestPost
      ...> )
      %{
        "id" => 1,
        "text" => "Welcome to my new blog!"
      }

  From the other side of the `belongs_to`, the `has_many` nested params are unchanged

      iex> Alembic.ToParams.nested_to_foreign_keys(
      ...>   %{
      ...>     "id" => 2,
      ...>     "name" => "Alice",
      ...>     "posts" => [
      ...>       %{
      ...>         "id" => 1,
      ...>         "text" => "Welcome to my new blog!"
      ...>       }
      ...>     ]
      ...>   },
      ...>   Alembic.TestAuthor
      ...> )
      %{
        "id" => 2,
        "name" => "Alice",
        "posts" => [
          %{
            "id" => 1,
            "text" => "Welcome to my new blog!"
          }
        ]
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
         association = %Ecto.Association.BelongsTo{field: field},
         acc
       ) do
    param_name = to_string(field)

    case Map.fetch(acc, param_name) do
      {:ok, association_params} ->
        replace_nested(acc, param_name, association_params, association)
      :error ->
        acc
    end
  end

  defp reduce_nested_association_params_to_foreign_keys(_, acc), do: acc

  defp replace_nested(params, association_param_name, nil, %Ecto.Association.BelongsTo{owner_key: owner_key}) do
    replace_nested_with_owner(params, association_param_name, owner_key, nil)
  end

  defp replace_nested(
         params,
         association_param_name,
         association_params,
         %Ecto.Association.BelongsTo{owner_key: owner_key, related_key: related_key}
       ) do
    case Map.fetch(association_params, to_string(related_key)) do
      {:ok, foreign_key_value} ->
        replace_nested_with_owner(params, association_param_name, owner_key, foreign_key_value)
      :error ->
        params
    end
  end

  defp replace_nested_with_foreign(params, nested_param_name, foreign_key_param_name, foreign_key_value)
       when is_binary(nested_param_name) and is_binary(foreign_key_param_name) do
    params
    |> Map.delete(nested_param_name)
    |> Map.put(foreign_key_param_name, foreign_key_value)
  end

  defp replace_nested_with_owner(params, nested_param_name, owner_key, owner_key_value)
       when is_map(params) and is_binary(nested_param_name) and is_atom(owner_key) do
    foreign_key_param_name = to_string(owner_key)

    replace_nested_with_foreign(params, nested_param_name, foreign_key_param_name, owner_key_value)
  end
end
