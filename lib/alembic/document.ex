defmodule Alembic.Document do
  alias Alembic.Resource

  # Struct

  defstruct data: :unset,
            included: nil

  @type t :: %__MODULE__{
               data: nil,
               included: nil
             } |
             %__MODULE__{
               data: nil,
               included: nil
             } |
             %__MODULE__{
               data: [Resource.t] | Resource.t,
               included: [Resource.t] | nil
             }
end
