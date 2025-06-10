defmodule Smalltalk.SeedFactories.Accounts do
  use SeedFactory.Schema

  alias Smalltalk.Accounts

  command :create_user do
    param(:email, generate: &Faker.Internet.email/0)
    param(:password, value: "password")

    resolve(fn args ->
      user =
        Accounts.User
        |> Ash.Changeset.for_create(
          :register_with_password,
          Map.put(args, :password_confirmation, args.password)
        )
        |> Ash.create!(authorize?: false)

      {:ok, %{user: user}}
    end)

    produce(:user)
  end
end
