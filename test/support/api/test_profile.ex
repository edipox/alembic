defmodule Alembic.TestProfile do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "profiles" do
    field :image_url, :string

    belongs_to :author, Alembic.TestAuthor
  end
end
