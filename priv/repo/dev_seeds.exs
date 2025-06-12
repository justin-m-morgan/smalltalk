# Script for populating the database. You can run it as:
#
#     mix run priv/repo/dev_seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Smalltalk.Repo.insert!(%Smalltalk.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


for _ <- 1..100 do
  %{}
  |> SeedFactory.init(Smalltalk.SeedFactories.Conversations)
  |> SeedFactory.produce(:profile)
end
