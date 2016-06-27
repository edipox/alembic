defmodule Alembic.Document do
  alias Alembic.Resource

  # Struct

  defstruct data: :unset,
            errors: nil,
            included: nil,
            jsonapi: nil,
            links: nil,
            meta: nil

  @type t :: %__MODULE__{
               data: nil,
               errors: list,
               included: nil,
               links: map | nil,
               meta: map | nil
             } |
             %__MODULE__{
               data: nil,
               errors: nil,
               included: nil,
               links: map | nil,
               meta: map
             } |
             %__MODULE__{
               data: [Resource.t] | Resource.t,
               errors: nil,
               included: [Resource.t] | nil,
               links: map | nil,
               meta: map | nil
             }
end
