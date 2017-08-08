defmodule Alembic.TestPost do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "posts" do
    field :text, :string

    timestamps()

    belongs_to :author, Alembic.TestAuthor
    has_many :comments, Alembic.TestComment
    many_to_many :tags, Alembic.TestTag, join_through: "posts_tags", on_replace: :delete
  end
end
