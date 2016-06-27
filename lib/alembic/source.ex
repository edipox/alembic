defmodule Alembic.Source do
  @moduledoc """
  The `source` of an error.
  """

  # Constants

  @parameter_options %{
                       field: :parameter,
                       member: %{
                         from_json: &FromJson.string_from_json/2
                       }
                     }

  # Struct

  defstruct [:parameter, :pointer]

  # Types

  @typedoc """
  An object containing references to the source of the [error](http://jsonapi.org/format/#error-objects), optionally
  including any of the following members:

  * `pointer` - JSON Pointer ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request
    document (e.g. `"/data"` for a primary data object, or `"/data/attributes/title"` for a specific attribute).
  * `parameter` - URL query parameter caused the error.
  """
  @type t :: %__MODULE__{
               parameter: String.t,
               pointer: Api.json_pointer
             }

  @doc """
  Descends `pointer` to `child` of current `pointer`

      iex> Alembic.Source.descend(
      ...>   %Alembic.Source{
      ...>     pointer: "/data"
      ...>   },
      ...>   1
      ...> )
      %Alembic.Source{
        pointer: "/data/1"
      }

  """
  @spec descend(t, String.t | integer) :: t
  def descend(source = %__MODULE__{pointer: pointer}, child) do
    %__MODULE__{source | pointer: "#{pointer}/#{child}"}
  end

  defimpl Poison.Encoder do
    alias Alembic.Source

    @doc """
    Encoded `Alembic.Source.t` as a `String.t` contain a JSON object with either a `"parameter"` or `"pointer"` member.
    Whichever field is `nil` in the `Alembic.Source.t` does not appear in the output.

    If `parameter` is set in the `Alembic.Source.t`, then the encoded JSON will only have "parameter"

        iex> Poison.encode(
        ...>   %Alembic.Source{
        ...>     parameter: "q"
        ...>   }
        ...> )
        {:ok, "{\\"parameter\\":\\"q\\"}"}

    If `pointer` is set in the `Alembic.Source.t`, then the encoded JSON will only have "pointer"

        iex> Poison.encode(
        ...>   %Alembic.Source{
        ...>     pointer: "/data"
        ...>   }
        ...> )
        {:ok, "{\\"pointer\\":\\"/data\\"}"}

    """
    # work-around https://github.com/elixir-lang/elixir/issues/4874
    @spec encode(Source.t, Keyword.t) :: String.t

    def encode(%@for{parameter: parameter, pointer: nil}, options) when is_binary(parameter) do
      Poison.Encoder.Map.encode(%{"parameter" => parameter}, options)
    end

    def encode(%@for{parameter: nil, pointer: pointer}, options) when is_binary(pointer) do
      Poison.Encoder.Map.encode(%{"pointer" => pointer}, options)
    end
  end
end
