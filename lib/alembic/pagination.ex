defmodule Alembic.Pagination do
  @moduledoc """
  Pagination by fixed-size pages
  """

  alias Alembic.Page

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
end
