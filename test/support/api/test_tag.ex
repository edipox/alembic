defmodule Alembic.TestTag do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "tags" do
    field :name, :string

    timestamps()

    many_to_many :posts, Alembic.TestPost, join_through: "posts_tags", on_replace: :delete
  end
end
