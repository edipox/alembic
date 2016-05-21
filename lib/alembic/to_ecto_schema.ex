defmodule Alembic.ToEctoSchema do
  @moduledoc """
  The `Alembic.ToEctoSchema` behaviour converts a struct in the `Alembic` namespace to
  an `Ecto.Schema.t` struct.
  """

  alias Alembic.Resource
  alias Alembic.ToParams

  # Types

  @typedoc """
  * `nil` if an empty singleton
  * `struct` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[struct]` - if a non-empty collection
  """
  @type ecto_schema :: nil | struct | [] | [struct, ...]

  @typedoc """
  A module that defines `__struct__/0` and `__schema__(:fields)` as happens when `use Ecto.Schema` is run in a module.
  """
  @type ecto_schema_module :: atom

  @typedoc """
  Maps JSON API `Alembic.Resource.type` to `ecto_schema_module` for casting that
  `Alembic.Resource.type`.
  """
  @type ecto_schema_module_by_type :: %{Resource.type => ecto_schema_module}

  # Callbacks

  @doc """
  ## Parameters

  * `struct` - an `Alembic.Document.t` hierarchy struct
  * `attributes_by_id_by_type` - Maps a resource identifier's `Alembic.ResourceIdentifier.type` and
    `Alembic.ResourceIdentifier.id` to its `Alembic.Resource.attributes` from
    `Alembic.Document.t` `included`.
  * `ecto_schema_module_by_type` -

  ## Returns

  * `nil` if an empty singleton
  * `struct` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[struct]` - if a non-empty collection
  """
  @callback to_ecto_schema(struct, ToParams.resource_by_id_by_type, ecto_schema_module_by_type) :: ecto_schema

  # Functions

  @spec to_ecto_schema(ToParams.params, ecto_schema_module) :: struct
  # prefer to keep Ecto.Changeset instead of Changeset
  @lint {Credo.Check.Design.AliasUsage, false}
  def to_ecto_schema(params, ecto_schema_module) when is_atom(ecto_schema_module) do
    changeset = Ecto.Changeset.cast(ecto_schema_module.__struct__, params, [], ecto_schema_module.__schema__(:fields))

    field_struct = struct(ecto_schema_module, changeset.changes)

    :associations
    |> ecto_schema_module.__schema__
    |> Enum.reduce(field_struct, fn (association_name, acc) ->
         put_named_association(acc, params, ecto_schema_module, association_name)
       end)
  end

  @spec to_ecto_schema(%{type: Resource.type}, ToParams.params, ecto_schema_module_by_type) :: struct
  def to_ecto_schema(%{type: type}, params, ecto_schema_module_by_type) do
    ecto_schema_module = Map.fetch!(ecto_schema_module_by_type, type)
    to_ecto_schema(params, ecto_schema_module)
  end

  ## Private Functions

  defp put_association(acc, relationship_params, %Ecto.Association.BelongsTo{field: field, owner_key: owner_key, related: related}) do
    associated = case relationship_params do
      map when is_map(map) -> to_ecto_schema(map, related)
      nil -> nil
    end

    acc_with_associated = %{acc | field => associated}

    case associated do
      %{id: id} ->
        %{acc_with_associated | owner_key => id}
      _ ->
        acc_with_associated
    end
  end

  defp put_association(acc, relationship_params, %Ecto.Association.Has{cardinality: :many, field: field, related: related}) do
    associated = case relationship_params do
      list when is_list(list) ->
        Enum.map(list, &to_ecto_schema(&1, related))
      nil ->
        nil
    end

    %{acc | field => associated}
  end

  defp put_association(acc, relationship_params, %Ecto.Association.Has{cardinality: :one, field: field, related: related}) do
    associated = case relationship_params do
      map when is_map(map) -> to_ecto_schema(map, related)
      nil -> nil
    end

    %{acc | field => associated}
  end

  def put_named_association(acc, params, ecto_schema_module, association_name) do
    relationship_name = to_string(association_name)

    case Map.fetch(params, relationship_name) do
      {:ok, relationship_params} ->
        association = ecto_schema_module.__schema__(:association, association_name)
        put_association(acc, relationship_params, association)
      :error ->
        acc
    end
  end
end
