defmodule Ash.Test.Actions.IdentityTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Ash.Test.AnyApi, as: Api

  defmodule Post do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    def testing_identities, do: true

    identities do
      identity :unique_title, [:title] do
        eager_check_with(Api)
      end

      identity :unique_url, [:url] do
        pre_check_with(Api)
      end
    end

    actions do
      defaults [:create, :read, :update, :destroy]

      create :create_with_required do
        require_attributes [:tag]
      end
    end

    attributes do
      uuid_primary_key :id
      attribute(:title, :string, allow_nil?: false)
      attribute(:url, :string)
    end
  end

  describe "eager_check_with" do
    test "will check for an identity mismatch at validation" do
      Post
      |> Ash.Changeset.for_create(:create, %{title: "fred"}, api: Api)
      |> Api.create!()

      assert %{
               valid?: false,
               errors: [
                 %Ash.Error.Changes.InvalidChanges{
                   fields: [:title],
                   message: "has already been taken"
                 }
               ]
             } = Ash.Changeset.for_create(Post, :create, %{title: "fred"})
    end
  end

  describe "pre_check?" do
    test "will check for an identity mismatch prior to submission" do
      Post
      |> Ash.Changeset.for_create(:create, %{title: "fred", url: "google.com"}, api: Api)
      |> Api.create!()

      assert_raise Ash.Error.Invalid, ~r/url: has already been taken/, fn ->
        Post
        |> Ash.Changeset.for_create(:create, %{title: "george", url: "google.com"})
        |> Api.create!()
      end
    end
  end
end
