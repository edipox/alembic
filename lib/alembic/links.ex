defmodule Alembic.Links do
  @moduledoc """
  > Where specified, a `links` member can be used to represent links. The value of each `links` member **MUST** be an
  > object (a "links object").
  >
  > -- <cite>
  >  [JSON API - Document Structure - Links](http://jsonapi.org/format/#document-links)
  > </cite>
  """

  alias Alembic.{Document, Error, FromJson, Link, Pagination}

  # Behaviours

  @behaviour FromJson
  @behaviour Pagination

  # Constants

  @human_type "links object"
  @pagination_field_by_key %{
    "first" => :first,
    "last" => :last,
    "next" => :next,
    "prev" => :previous
  }

  # Types

  @typedoc """
  Maps `String.t` name to `Alembic.Link.link`
  """
  @type t :: %{String.t => Link.link}

  # Functions

  @doc """
  Validates that the given `json` follows the spec for ["links"](http://jsonapi.org/format/#document-links) and converts
  any child "links" to `Alembic.Link`.

  In a most locations, `"links"` is optional, so it can be nil.

      iex> Alembic.Links.from_json(
      ...>   nil,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links"
      ...>     }
      ...>   }
      ...> )
      {:ok, nil}

  # Links

  > The value of each `links` member MUST be an object (a "links object").
  >
  > -- <cite>
  >  [JSON API - Document Structure - Links](http://jsonapi.org/format/#document-links)
  > </cite>

      iex> Alembic.Links.from_json(
      ...>   ["http://example.com"],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links` type is not links object",
              meta: %{
                "type" => "links object"
              },
              source: %Alembic.Source{
                pointer: "/links"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  Because the members of a "links object" are free-form, even an empty object is ok

      iex> Alembic.Links.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links"
      ...>     }
      ...>   }
      ...> )
      {:ok, %{}}

  # Link values

  > Each member of a links object is a "link". A link MUST be represented as either:
  >
  > * a string containing the link's URL.
  > * an object ("link object") which can contain the following members:
  >   * `href` - a string containing the link's URL.
  >   * `meta` - a meta object containing non-standard meta-information about the link.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Links](http://jsonapi.org/format/#document-links)
  > </cite>

      iex> Alembic.Links.from_json(
      ...>   %{
      ...>     "string" => "http://example.com",
      ...>     "link_object" => %{
      ...>       "href" => "http://example.com",
      ...>       "meta" => %{
      ...>         "last_updated_on" => "2015-12-21"
      ...>       }
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "link_object" => %Alembic.Link{
            href: "http://example.com",
            meta: %{
              "last_updated_on" => "2015-12-21"
            }
          },
          "string" => "http://example.com"
        }
      }

  When any link has an error, then only errors will be returned, but errors from later links will be included

      iex> Alembic.Links.from_json(
      ...>   %{
      ...>     "first_ok" => "http://example.com/first_ok",
      ...>     "first_error" => [],
      ...>     "second_ok" => "http://example.com/second_ok",
      ...>     "second_error" => []
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links/first_error` type is not link object",
              meta: %{
                "type" => "link object"
              },
              source: %Alembic.Source{
                pointer: "/links/first_error"
              },
              status: "422",
              title: "Type is wrong"
            },
            %Alembic.Error{
              detail: "`/links/second_error` type is not link object",
              meta: %{
                "type" => "link object"
              },
              source: %Alembic.Source{
                pointer: "/links/second_error"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """
  def from_json(json, error_template)

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, map} | FromJson.error
  def from_json(link_by_name = %{}, error_template) do
    link_by_name
    |> Enum.reduce({:ok, %{}}, &validate_link_pair(&1, &2, error_template))
    |> FromJson.reverse
  end

  @spec from_json(nil, Error.t) :: {:ok, nil}
  def from_json(nil, _), do: {:ok, nil}

  # Alembic.json -- [Alembic.json_object, nil]
  @spec from_json(true | false | list | float | integer | String.t, Error.t) :: FromJson.error
  def from_json(_, error_template) do
    {
      :error,
      %Document{
        errors: [
          Error.type(error_template, @human_type)
        ]
      }
    }
  end

  @doc """
  Converts the links to `Alembic.Pagination.t` page fields

  ## Single Page

  When there is only one page, there will be a `"first"` and `"last"` link pointing to the same page, but no
  "next" or "prev" links.

      iex> Alembic.Links.to_pagination(
      ...>   %{
      ...>     "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
      ...>     "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10"
      ...>   }
      ...> )
      %Alembic.Pagination{
        first: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        },
        last: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        }
      }

  ## Multiple Pages

  When there are multiple pages, every page will have a `"first"` and `"last"` link pointing to the respective,
  different pages.

  On the first page, the `"next"` link will be set, but not the `"prev"` link.

      iex> Alembic.Links.to_pagination(
      ...>   %{
      ...>     "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
      ...>     "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
      ...>     "next" => "https://example.com/api/v1/users?page%5Bnumber%5D=2&page%5Bsize%5D=10"
      ...>   }
      ...> )
      %Alembic.Pagination{
        first: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        },
        last: %Alembic.Pagination.Page{
          number: 3,
          size: 10
        },
        next: %Alembic.Pagination.Page{
          number: 2,
          size: 10
        }
      }

  On any middle page, both the `"next"` and `"prev"` links will be set.

      iex> Alembic.Links.to_pagination(
      ...>   %{
      ...>     "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
      ...>     "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
      ...>     "next" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
      ...>     "prev" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10"
      ...>   }
      ...> )
      %Alembic.Pagination{
        first: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        },
        last: %Alembic.Pagination.Page{
          number: 3,
          size: 10
        },
        next: %Alembic.Pagination.Page{
          number: 3,
          size: 10
        },
        previous: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        }
      }

  On the last page, the `"prev"` link will be set, but not the `"next"` link.

      iex> Alembic.Links.to_pagination(
      ...>   %{
      ...>     "first" => "https://example.com/api/v1/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
      ...>     "last" => "https://example.com/api/v1/users?page%5Bnumber%5D=3&page%5Bsize%5D=10",
      ...>     "prev" => "https://example.com/api/v1/users?page%5Bnumber%5D=2&page%5Bsize%5D=10"
      ...>   }
      ...> )
      %Alembic.Pagination{
        first: %Alembic.Pagination.Page{
          number: 1,
          size: 10
        },
        last: %Alembic.Pagination.Page{
          number: 3,
          size: 10
        },
        previous: %Alembic.Pagination.Page{
          number: 2,
          size: 10
        }
      }

  ## No Links

  If there are no links, then `nil` will be returned

      iex> Alembic.Links.to_pagination(nil)
      nil

  ## No pagination links

  If there are links, but not for pagination, then `nil` will be returned

      iex> Alembic.Links.to_pagination(%{ "about" => "https://example.com/about" })
      nil

  """
  def to_pagination(links)

  @spec to_pagination(nil) :: nil
  def to_pagination(nil), do: nil

  @spec to_pagination(t) :: Pagination.t
  def to_pagination(links) when is_map(links) do
    reduced = Enum.reduce(@pagination_field_by_key, %Pagination{}, &reduce_links_key_field_to_pagination(links, &1, &2))

    case reduced do
      %Pagination{first: nil, last: nil, next: nil, previous: nil} ->
        nil
      pagination ->
        pagination
    end
  end

  ## Private Functions

  defp reduce_links_key_field_to_pagination(links, {key, field}, acc = %Pagination{}) when is_map(links) do
    case Map.fetch(links, key) do
      {:ok, link} ->
        %{acc | field => Link.to_page(link)}
      :error ->
        acc
    end
  end

  defp validate_link_pair({key, value_json}, collectable_result, error_template) do
    key_error_template = Error.descend(error_template, key)

    field_result = value_json
                   |> Link.from_json(key_error_template)
                   |> FromJson.put_key(key)

    FromJson.merge(collectable_result, field_result)
  end
end
