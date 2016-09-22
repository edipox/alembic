defmodule Alembic.Pagination do
  @moduledoc """
  Pagination by fixed-size pages
  """

  alias Alembic.{Links, Pagination.Page}

  # Constants

  @links_key_by_field %{
    :first => "first",
    :last => "last",
    :next => "next",
    :previous => "prev"
  }

  # Struct

  defstruct ~w(first last next previous total_size)a

  # Types

  @typedoc """
  * `first` - the first `Page.t`
  * `last` - the last `Page.t`
  * `next` - the next `Page.t`
  * `previous` - the previous `Page.t`
  * `total_size` - the total number of all resources that can be paged.
  """
  @type t :: %__MODULE__{
               first: Page.t,
               last: Page.t,
               next: Page.t,
               previous: Page.t,
               total_size: non_neg_integer
             }

  # Callbacks

  @doc """
  Converts the module's type to a `t` or `nil` if there is no pagination information.
  """
  @callback to_pagination(any) :: t | nil

  # Functions

  @doc """
  Converts `t` back to the named `Links.t`

  ## Single Page

  When there is only one page, there will be a `"first"` and `"last"` link pointing to the same page, but no
  "next" or "prev" links.

      iex> Alembic.Pagination.to_links(
      ...>   %Alembic.Pagination{
      ...>     first: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     },
      ...>     last: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     }
      ...>   },
      ...>   URI.parse("https://example.com/api/v1/users")
      ...> )
      %{
        "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
        "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10"
      }

  ## Multiple Pages

  When there are multiple pages, every page will have a `"first"` and `"last"` link pointing to the respective,
  different pages.

  On the first page, the `"next"` link will be set, but not the `"prev"` link.

      iex> Alembic.Pagination.to_links(
      ...>   %Alembic.Pagination{
      ...>     first: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     },
      ...>     last: %Alembic.Pagination.Page{
      ...>       number: 3,
      ...>       size: 10
      ...>     },
      ...>     next: %Alembic.Pagination.Page{
      ...>       number: 2,
      ...>       size: 10
      ...>     }
      ...>   },
      ...>   URI.parse("https://example.com/api/v1/users")
      ...> )
      %{
        "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
        "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
        "next" => "https://example.com/api/v1/users?page%5Bnumber%5D=2&page%5Bsize%5D=10"
      }

  On any middle page, both the `"next"` and `"prev"` links will be set.

      iex> Alembic.Pagination.to_links(
      ...>   %Alembic.Pagination{
      ...>     first: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     },
      ...>     last: %Alembic.Pagination.Page{
      ...>       number: 3,
      ...>       size: 10
      ...>     },
      ...>     next: %Alembic.Pagination.Page{
      ...>       number: 3,
      ...>       size: 10
      ...>     },
      ...>     previous: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     }
      ...>   },
      ...>   URI.parse("https://example.com/api/v1/users")
      ...> )
      %{
        "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
        "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
        "next" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
        "prev" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10"
      }

  On the last page, the `"prev"` link will be set, but not the `"next"` link.

      iex> Alembic.Pagination.to_links(
      ...>   %Alembic.Pagination{
      ...>     first: %Alembic.Pagination.Page{
      ...>       number: 1,
      ...>       size: 10
      ...>     },
      ...>     last: %Alembic.Pagination.Page{
      ...>       number: 3,
      ...>       size: 10
      ...>     },
      ...>     previous: %Alembic.Pagination.Page{
      ...>       number: 2,
      ...>       size: 10
      ...>     }
      ...>   },
      ...>   URI.parse("https://example.com/api/v1/users")
      ...> )
      %{
        "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
        "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
        "prev" => "https://example.com/api/v1/users?page%5Bnumber%5D=2&page%5Bsize%5D=10"
      }

  ## No Links

  If there are no links, then `nil` will be returned

      iex> Alembic.Pagination.to_links(nil, URI.parse("https://example.com/api/v1/users"))
      nil

  """
  @spec to_links(nil, URI.t) :: nil
  @spec to_links(t, URI.t) :: Links.t
  def to_links(nil, %URI{}), do: nil
  def to_links(pagination = %__MODULE__{}, base_uri = %URI{}) do
    Enum.reduce(@links_key_by_field, %{}, &reduce_field_key_to_links(pagination, base_uri, &1, &2))
  end

  ## Private Functions

  def reduce_field_key_to_links(pagination = %__MODULE__{}, base_uri = %URI{}, {field, key}, acc) when is_map(acc) do
    case get_in(pagination, [Access.key!(field)]) do
      page = %Page{} ->
        Map.put(acc, key, URI.to_string(%{base_uri | query: Page.to_query(page)}))
      nil ->
        acc
    end
  end
end
