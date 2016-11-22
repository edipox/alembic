defmodule Alembic.Fetch.Sorts do
  @moduledoc """
  [Fetching Data > Sorting](http://jsonapi.org/format/#fetching-sorting)
  """

  alias Alembic.Fetch.Sort

  # Types

  @type params :: %{}

  @typedoc """
  An order `list` of `Alembic.Fetch.Sort.t`
  """
  @type t :: [Sort.t]

  # Functions

  @doc """
  Extracts `t` from `"sort"` in `params`

  `params` without `"sort"` will have no sorts

      iex> Alembic.Fetch.Sorts.from_params(%{})
      []

  `params` with `"sort"` will have the value of `"sort"` broken into `t`

      iex> Alembic.Fetch.Sorts.from_params(
      ...>   %{
      ...>     "sort" => "-inserted-at,author.name,-comments.author.posts.inserted-at"
      ...>   }
      ...> )
      [
        %Alembic.Fetch.Sort{attribute: "inserted-at", direction: :descending, relationship: nil},
        %Alembic.Fetch.Sort{attribute: "name", direction: :ascending, relationship: "author"},
        %Alembic.Fetch.Sort{
          attribute: "inserted-at",
          direction: :descending,
          relationship: %{
            "comments" => %{
              "author" => "posts"
            }
          }
        }
      ]

  """
  @spec from_params(params) :: t
  def from_params(params) when is_map(params) do
    case Map.fetch(params, "sort") do
      :error ->
        []
      {:ok, sort} ->
        from_string(sort)
    end
  end

  @doc """
  Breaks the `sort` into list of `Alembic.Fetch.Sort.t`

  An empty String will have no sorts

      iex> Alembic.Fetch.Sorts.from_string("")
      []

  A single attribute name will have the default direction of `:ascending` and no `:relationship`

      iex> Alembic.Fetch.Sorts.from_string("inserted-at")
      [%Alembic.Fetch.Sort{attribute: "inserted-at", direction: :ascending, relationship: nil}]

  An attribute name with `-` before will have the direction reversed to `:descending`.

      iex> Alembic.Fetch.Sorts.from_string("-inserted-at")
      [%Alembic.Fetch.Sort{attribute: "inserted-at", direction: :descending, relationship: nil}]

  In a dot-seperated sequence of names, the final name is the attribute name and all preceding names are a relationship
  path in the same format as `Alembic.RelationshipPath`

      iex> Alembic.Fetch.Sorts.from_string("author.name,-comments.author.posts.inserted-at")
      [
        %Alembic.Fetch.Sort{attribute: "name", direction: :ascending, relationship: "author"},
        %Alembic.Fetch.Sort{
          attribute: "inserted-at",
          direction: :descending,
          relationship: %{
            "comments" => %{
              "author" => "posts"
            }
          }
        }
      ]
  """
  @spec from_string(String.t) :: t
  def from_string(comma_seperated_sorts) do
    comma_seperated_sorts
    |> String.splitter(sort_separator(), trim: true)
    |> Enum.map(&Sort.from_string/1)
  end

  @doc """
  Separates each sort in `"sort"`
  """
  def sort_separator, do: ","

  @doc """
  Converts a list of `Alembic.Fetch.Sort.t` back to a string
  """
  @spec to_string(t) :: String.t
  def to_string(sorts) when is_list(sorts) do
    sorts
    |> Stream.map(&Sort.to_string/1)
    |> Enum.join(sort_separator())
  end
end
