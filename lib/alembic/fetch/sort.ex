defmodule Alembic.Fetch.Sort do
  @moduledoc """
  An individual sort in an `Alembic.Fetch.Sorts.t`
  """

  alias Alembic.Fetch.Includes

  import Alembic.RelationshipPath, only: [reverse_relationship_names_to_include: 1]

  # Struct

  defstruct attribute: nil,
            direction: :ascending,
            relationship: nil

  # Types

  @typedoc """
  The name of an attribute on the primary data or relationship to sort
  """
  @type attribute_name :: String.t

  @typedoc """
  The direction to sort.  Default to `:ascending` per the JSONAPI spec.  Can be `:descending` when the dot-separated
  attribute path is prefixed with `-`.
  """
  @type direction :: :ascending | :descending

  @typedoc """
  * `:attribute` - the name of the attribute to sort
  * `:direction` - the direction to sort `:attribute`.  Defaults to `:ascending`.  Can also be `:descending`.
  * `:relationship` - the path to the relationship `:attribute` is on.  `nil` means the attribute is on the primary data
  """
  @type t :: %__MODULE__{
               attribute: attribute_name,
               direction: direction,
               relationship: Includes.include | nil,
             }

  def related_attribute_path_separator, do: "."

  @doc """
  Breaks the (optionally prefixed) attribute path into a `t`.

  A single attribute name will have the default direction of `:ascending` and no `:relationship`

      iex> Alembic.Fetch.Sort.from_string("inserted-at")
      %Alembic.Fetch.Sort{attribute: "inserted-at", direction: :ascending, relationship: nil}

  An attribute name with `-` before it will have the direction reversed to `:descending`.

      iex> Alembic.Fetch.Sort.from_string("-inserted-at")
      %Alembic.Fetch.Sort{attribute: "inserted-at", direction: :descending, relationship: nil}

  In a dot-separated sequence of names, the final name is the attribute name and all preceding names are a relationship
  path in the same format as `Alembic.RelationshipPath`

      iex> Alembic.Fetch.Sort.from_string("author.name")
      %Alembic.Fetch.Sort{attribute: "name", direction: :ascending, relationship: "author"}
      iex> Alembic.Fetch.Sort.from_string("comments.author.posts.inserted-at")
      %Alembic.Fetch.Sort{
        attribute: "inserted-at",
        direction: :ascending,
        relationship: %{
          "comments" => %{
            "author" => "posts"
          }
        }
      }

  """
  @spec from_string(String.t) :: t
  def from_string(string) when is_binary(string) do
    {direction, related_attribute_path} = case string do
      "-" <> descending_related_attribute_path -> {:descending, descending_related_attribute_path}
      ascending_related_attribute_path -> {:ascending, ascending_related_attribute_path}
    end

    put_related_attribute_path(%__MODULE__{direction: direction}, related_attribute_path)
  end

  @doc """
  Converts a sort back to the string format parsed by `from_string/1`

  A `t` with `nil` relationship and the default direction of `:ascending` is only the `attribute`

      iex> Alembic.Fetch.Sort.to_string(
      ...>   %Alembic.Fetch.Sort{attribute: "inserted-at", relationship: nil}
      ...> )
      "inserted-at"

  A `t` with direction of `:descending` will have a `"-"` prefix

      iex> Alembic.Fetch.Sort.to_string(
      ...>   %Alembic.Fetch.Sort{attribute: "inserted-at", direction: :descending, relationship: nil}
      ...> )
      "-inserted-at"

  When there is a relationship, it is converted to a path in front of the attribute name, but after the direction prefix

      iex> Alembic.Fetch.Sort.to_string(
      ...>   %Alembic.Fetch.Sort{attribute: "inserted-at", direction: :descending, relationship: "comments"}
      ...> )
      "-comments.inserted-at"

  Farther relationships are dot-separated

      iex> Alembic.Fetch.Sort.to_string(
      ...>   %Alembic.Fetch.Sort{
      ...>     attribute: "inserted-at",
      ...>     direction: :descending,
      ...>     relationship: %{
      ...>       "comments" => %{
      ...>         "author" => "posts"
      ...>       }
      ...>     }
      ...>   }
      ...> )
      "-comments.author.posts.inserted-at"

  """
  @spec to_string(t) :: String.t
  def to_string(sort), do: prefix(sort) <> related_attribute_path(sort)

  ## Private Functions

  defp prefix(%__MODULE__{direction: :ascending}), do: ""
  defp prefix(%__MODULE__{direction: :descending}), do: "-"

  # Break up `related_attribute_path` into `relationship` and `attribute` components and puts them into `sort`
  defp put_related_attribute_path(sort = %__MODULE__{}, related_attribute_path) do
    [attribute_name | reverse_relationship_names] = related_attribute_path
                                                   |> String.split(related_attribute_path_separator())
                                                   |> Enum.reverse()

    relationship = reverse_relationship_names_to_include(reverse_relationship_names)

    %__MODULE__{sort | attribute: attribute_name, relationship: relationship}
  end

  defp related_attribute_path(%__MODULE__{attribute: attribute, relationship: nil}), do: attribute
  defp related_attribute_path(%__MODULE__{attribute: attribute, relationship: relationship}) do
    Includes.to_relationship_path(relationship) <> related_attribute_path_separator() <> attribute
  end
end
