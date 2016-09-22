defmodule Alembic.Pagination.Page do
  @moduledoc """
  A page using paged pagination where the size of pages is fixed.
  """

  # Struct

  defstruct number: 1,
            size: 10

  # Types

  @typedoc """
  * `number` - the 1-based page number
  * `size` - the size of this page and all pages
  """
  @type t :: %__MODULE__{
               number: non_neg_integer,
               size: pos_integer
             }

  # Functions

  @doc """
  Extracts `number` from `query` `"page[number]"` and and `size` from `query` `"page[size]"`.

      iex> Alembic.Pagination.Page.from_query("page%5Bnumber%5D=2&page%5Bsize%5D=10")
      %Alembic.Pagination.Page{number: 2, size: 10}

  If `query` does not have both `"page[number]"` and `"page[size]"` then `nil` is returned

      iex> Alembic.Pagination.Page.from_query("page%5Bnumber%5D=2")
      nil
      iex> Alembic.Pagination.Page.from_query("page%5Bsize%5D=10")
      nil
      iex> Alembic.Pagination.Page.from_query("")
      nil

  """
  @spec from_query(String.t) :: t
  def from_query(query) when is_binary(query) do
    reduced = query |>
              URI.query_decoder
              |> Enum.reduce(%__MODULE__{number: :unset, size: :unset}, &reduce_decoded_query_to_page/2)

    case reduced do
      %__MODULE__{number: number, size: size} when number == :unset or size == :unset ->
        nil
      set = %__MODULE__{} ->
        set
    end
  end

  @doc """
  Extracts `number` from `uri` `query` `"page[number]"` and `size` from `uri` `query` `"page[size]"`.

      iex> Alembic.Pagination.Page.from_uri(%URI{query: "page%5Bnumber%5D=2&page%5Bsize%5D=10"})
      %Alembic.Pagination.Page{number: 2, size: 10}

  If a `URI.t` `query` does not have both `"page[number]"` and `"page[size]"` then `nil` is returned

      iex> Alembic.Pagination.Page.from_uri(%URI{query: "page%5Bnumber%5D=2"})
      nil
      iex> Alembic.Pagination.Page.from_uri(%URI{query: "page%5Bsize%5D=10"})
      nil
      iex> Alembic.Pagination.Page.from_uri(%URI{query: ""})
      nil

  If a `URI.t` does not have a query then `nil` is returned

      iex> Alembic.Pagination.Page.from_uri(%URI{query: nil})
      nil

  """
  @spec from_uri(URI.t) :: t | nil
  def from_uri(uri)
  def from_uri(%URI{query: nil}), do: nil
  def from_uri(%URI{query: query}), do: from_query(query)

  @doc """
  Converts the `page` back to params.

      iex> Alembic.Pagination.Page.to_params(%Alembic.Pagination.Page{number: 2, size: 10})
      %{
        "page" => %{
          "number" => 2,
          "size" => 10
        }
      }

  """
  @spec to_params(t) :: map
  def to_params(page)
  def to_params(%__MODULE__{number: number, size: size}) do
    %{
      "page" => %{
        "number" => number,
        "size" => size
      }
    }
  end

  @doc """
  Converts the `page` back to query portion of URI

      iex> Alembic.Pagination.Page.to_query(%Alembic.Pagination.Page{number: 2, size: 10})
      "page%5Bnumber%5D=2&page%5Bsize%5D=10"

  """
  @spec to_query(t) :: String.t
  def to_query(%__MODULE__{number: number, size: size}) do
    URI.encode_query ["page[number]": number, "page[size]": size]
  end

  ## Private Functions

  defp reduce_decoded_query_to_page({"page[number]", encoded_page_number}, page = %__MODULE__{}) do
    %__MODULE__{page | number: String.to_integer(encoded_page_number)}
  end

  defp reduce_decoded_query_to_page({"page[size]", encoded_page_size}, page = %__MODULE__{}) do
    %__MODULE__{page | size: String.to_integer(encoded_page_size)}
  end

  defp reduce_decoded_query_to_page(_, page = %__MODULE__{}), do: page
end
