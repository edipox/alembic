defmodule Alembic.Document do
  @moduledoc """
  JSON API refers to the top-level JSON structure as a [document](http://jsonapi.org/format/#document-structure).
  """

  alias Alembic.Error
  alias Alembic.Links
  alias Alembic.Meta
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

  @links_options %{
                   field: :links,
                   member: %{
                     module: Links,
                     name: "links"
                   }
                 }

  @minimum_children ~w{data errors meta}

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  }
                }

  # DOES NOT include `@errors_options` because `&FromJson.from_json_array(&1, &2, Error)` cannot appear in a module
  #   attribute used in a function
  # DOES NOT include `@included_options` because `&FromJson.from_json_array(&1, &2, Resource)` cannot appear in a module
  #   attribute used in a function
  @child_options_list [
    @data_options,
    @links_options,
    @meta_options
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
               errors: [Error.t],
               included: nil,
               links: Links.t | nil,
               meta: Meta.t | nil
             } |
             %__MODULE__{
               data: nil,
               errors: nil,
               included: nil,
               links: Links.t | nil,
               meta: Meta.t
             } |
             %__MODULE__{
               data: [Resource.t] | Resource.t,
               errors: nil,
               included: [Resource.t] | nil,
               links: Links.t | nil,
               meta: Meta.t | nil
             }

  # Functions

  @doc """
  Tries to determine the common `Alembic.Error.t` `status` between all `errors` in the `document`.

  If it is not an errors document, `nil` is returned.

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{data: []}
      ...> )
      nil

  # Single error

  If there is one error, its status is returned.  This could be nil as no field is required in a JSONAPI error.

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         status: "404"
      ...>       }
      ...>     ]
      ...>   }
      ...> )
      "404"
      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{}
      ...>     ]
      ...>   }
      ...> )
      nil

  # Multiple errors

  If there are multiple errors with the same status, then that is the consensus

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         status: "404"
      ...>       },
      ...>       %Alembic.Error{
      ...>         status: "404"
      ...>       }
      ...>     ]
      ...>   }
      ...> )
      "404"

  If there are multiple errors, but some errors don't have statuses, they are ignored

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{},
      ...>       %Alembic.Error{
      ...>         status: "404"
      ...>       }
      ...>     ]
      ...>   }
      ...> )
      "404"

  If there are multiple errors, but they disagree within the same 100s block, then that is the consensus

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         status: "404"
      ...>       },
      ...>       %Alembic.Error{
      ...>         status: "422"
      ...>       }
      ...>     ]
      ...>   }
      ...> )
      "400"

  If there are multiple errors, but they disagree without the same 100s block, then the greater 100s block is the
  consensus

      iex> Alembic.Document.error_status_consensus(
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         status: "422"
      ...>       },
      ...>       %Alembic.Error{
      ...>         status: "500"
      ...>       }
      ...>     ]
      ...>   }
      ...> )
      "500"

  """
  def error_status_consensus(%__MODULE__{errors: nil}), do: nil

  def error_status_consensus(%__MODULE__{errors: errors}) do
    Enum.reduce errors, nil, fn
      %Error{status: status}, nil -> status
      %Error{status: status}, status -> status
      %Error{status: status}, consensus ->
        status_block_integer = div(String.to_integer(status), 100)
        consensus_block_integer = div(String.to_integer(consensus), 100)

        max_block_integer = max(status_block_integer, consensus_block_integer)
        to_string(max_block_integer * 100)
    end
  end

  @doc """
  Lookup table of `included` resources, so that `Alembic.ResourceIdentifier.t` can be
  converted to full `Alembic.Resource.t`.

  ## No included resources

  With no included resources, an empty map is returned

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => %{
      ...>       "type" => "post",
      ...>       "id" => "1"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      ...> Alembic.Document.included_resource_by_id_by_type(document)
      %{}

  ## Included resources

  With included resources, a nest map is built with the outer layer keyed by the `Alembic.Resource.type`,
  then the next layer keyed by the `Alembic.Resource.id` with the values being the full
  `Alembic.Resource.t`

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => [
      ...>       %{
      ...>         "type" => "articles",
      ...>         "id" => "1",
      ...>         "relationships" => %{
      ...>           "author" => %{
      ...>             "data" => %{
      ...>               "type" => "people",
      ...>               "id" => "9"
      ...>             }
      ...>           },
      ...>           "comments" => %{
      ...>             "data" => [
      ...>               %{
      ...>                 "type" => "comments",
      ...>                 "id" => "5"
      ...>               },
      ...>               %{
      ...>                 "type" => "comments",
      ...>                 "id" => "12"
      ...>               }
      ...>             ]
      ...>           }
      ...>         }
      ...>       }
      ...>     ],
      ...>     "included" => [
      ...>       %{
      ...>         "type" => "people",
      ...>         "id" => "9",
      ...>         "attributes" => %{
      ...>           "first-name" => "Dan",
      ...>           "last-name" => "Gebhardt",
      ...>           "twitter" => "dgeb"
      ...>         }
      ...>       },
      ...>       %{
      ...>         "type" => "comments",
      ...>         "id" => "5",
      ...>         "attributes" => %{
      ...>           "body" => "First!"
      ...>         },
      ...>         "relationships" => %{
      ...>           "author" => %{
      ...>             "data" => %{
      ...>               "type" => "people",
      ...>               "id" => "2"
      ...>             }
      ...>           }
      ...>         }
      ...>       },
      ...>       %{
      ...>         "type" => "comments",
      ...>         "id" => "12",
      ...>         "attributes" => %{
      ...>           "body" => "I like XML better"
      ...>         },
      ...>         "relationships" => %{
      ...>           "author" => %{
      ...>             "data" => %{
      ...>               "type" => "people",
      ...>               "id" => "9"
      ...>             }
      ...>           }
      ...>         }
      ...>       }
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      ...> Alembic.Document.included_resource_by_id_by_type(document)
      %{
        "comments" => %{
          "12" => %Alembic.Resource{
            attributes: %{
              "body" => "I like XML better"
            },
            id: "12",
            relationships: %{
              "author" => %Alembic.Relationship{
                data: %Alembic.ResourceIdentifier{
                  id: "9",
                  type: "people"
                }
              }
            },
            type: "comments"
          },
          "5" => %Alembic.Resource{
            attributes: %{
              "body" => "First!"
            },
            id: "5",
            relationships: %{
              "author" => %Alembic.Relationship{
                data: %Alembic.ResourceIdentifier{
                  id: "2",
                  type: "people"
                }
              }
            },
            type: "comments"
          }
        },
        "people" => %{
          "9" => %Alembic.Resource{
            attributes: %{
              "first-name" => "Dan",
              "last-name" => "Gebhardt",
              "twitter" => "dgeb"
            },
            id: "9",
            type: "people"
          }
        }
      }

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

  @spec merge(%__MODULE__{errors: [Error.t]}, %__MODULE__{errors: [Error.t]}) :: %__MODULE__{errors: [Error.t]}
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

      iex> merged = %Alembic.Document{
      ...>   errors: [
      ...>     %Alembic.Error{
      ...>       detail: "The index `2` of `/data` is not a resource",
      ...>       source: %Alembic.Source{
      ...>         pointer: "/data/2"
      ...>       },
      ...>       title: "Element is not a resource"
      ...>     },
      ...>     %Alembic.Error{
      ...>       detail: "The index `1` of `/data` is not a resource",
      ...>       source: %Alembic.Source{
      ...>         pointer: "/data/1"
      ...>       },
      ...>       title: "Element is not a resource"
      ...>     }
      ...>   ]
      ...> }
      iex> Alembic.Document.reverse(merged)
      %Alembic.Document{
        errors: [
          %Alembic.Error{
            detail: "The index `1` of `/data` is not a resource",
            source: %Alembic.Source{
              pointer: "/data/1"
            },
            title: "Element is not a resource"
          },
          %Alembic.Error{
            detail: "The index `2` of `/data` is not a resource",
            source: %Alembic.Source{
              pointer: "/data/2"
            },
            title: "Element is not a resource"
          }
        ]
      }

  """
  def reverse(document = %__MODULE__{errors: errors}) when is_list(errors) do
    %__MODULE__{document | errors: Enum.reverse(errors)}
  end

  @doc """
  Transforms a `t` into the nested params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## No resource

  No resource is transformed to an empty map

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => nil
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      iex> Alembic.Document.to_params(document)
      %{}

  ## Single resource

  A single resource is converted to a params map that combines the id and attributes.

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => %{
      ...>       "attributes" => %{
      ...>         "name" => "Thing 1"
      ...>       },
      ...>       "id" => "1",
      ...>       "type" => "thing"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      iex> Alembic.Document.to_params(document)
      %{
        "id" => "1",
        "name" => "Thing 1"
      }

  ### Relationships

  Relationships are merged into the params for the resource

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => %{
      ...>       "attributes" => %{
      ...>         "name" => "Thing 1"
      ...>       },
      ...>       "id" => "1",
      ...>       "relationships" => %{
      ...>         "shirt" => %{
      ...>           "data" => %{
      ...>             "attributes" => %{
      ...>               "size" => "L"
      ...>             },
      ...>             "type" => "shirt"
      ...>           }
      ...>         }
      ...>       },
      ...>       "type" => "thing"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      iex> Alembic.Document.to_params(document)
      %{
        "id" => "1",
        "name" => "Thing 1",
        "shirt" => %{
          "size" => "L"
        }
      }

  ## Multiple resources

  Multiple resources are converted to a params list where each element is a map that combines the id and attributes

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => [
      ...>       %{
      ...>         "type" => "post",
      ...>         "id" => "1",
      ...>         "attributes" => %{
      ...>           "text" => "Welcome"
      ...>         }
      ...>       },
      ...>       %{
      ...>         "type" => "post",
      ...>         "id" => "2",
      ...>         "attributes" => %{
      ...>           "text" => "It's been awhile"
      ...>         }
      ...>       }
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      iex> Alembic.Document.to_params(document)
      [
        %{
          "id" => "1",
          "text" => "Welcome"
        },
        %{
          "id" => "2",
          "text" => "It's been awhile"
        }
      ]

  ### Relationships

  Relationships are merged into the params for the corresponding resource

      iex> {:ok, document} = Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => [
      ...>       %{
      ...>         "type" => "post",
      ...>         "id" => "1",
      ...>         "attributes" => %{
      ...>           "text" => "Welcome"
      ...>         },
      ...>         "relationships" => %{
      ...>           "comments" => %{
      ...>             "data" => [
      ...>               %{
      ...>                 "type" => "comment",
      ...>                 "id" => "1"
      ...>               }
      ...>             ]
      ...>           }
      ...>         }
      ...>       },
      ...>       %{
      ...>         "type" => "post",
      ...>         "id" => "2",
      ...>         "attributes" => %{
      ...>           "text" => "It's been awhile"
      ...>         },
      ...>         "relationships" => %{
      ...>           "comments" => %{
      ...>             "data" => []
      ...>           }
      ...>         }
      ...>       }
      ...>     ],
      ...>     "included" => [
      ...>       %{
      ...>         "type" => "comment",
      ...>         "id" => "1",
      ...>         "attributes" => %{
      ...>           "text" => "First!"
      ...>         }
      ...>       }
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :fetch,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      iex> Alembic.Document.to_params(document)
      [
        %{
          "id" => "1",
          "text" => "Welcome",
          "comments" => [
            %{
              "id" => "1",
              "text" => "First!"
            }
          ]
        },
        %{
          "id" => "2",
          "text" => "It's been awhile",
          "comments" => []
        }
      ]

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
