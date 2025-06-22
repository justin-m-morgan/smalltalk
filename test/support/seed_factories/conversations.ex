defmodule Smalltalk.SeedFactories.Conversations do
  use SeedFactory.Schema

  include_schema(Smalltalk.SeedFactories.Accounts)

  alias Smalltalk.Conversations

  command :create_talker do
    param(:user, entity: :user)

    resolve(fn args ->
      {actor, args} = Map.pop(args, :user)
      {:ok, %{talker: Conversations.create_talker!(actor: actor)}}
    end)

    produce(:talker)
  end

  command :create_conversation do
    param(:talker, entity: :talker)
    param(:short_name, generate: fn -> Faker.Lorem.sentence(4..6) end)
    param(:description, generate: &Faker.Lorem.sentence/0)

    resolve(fn args ->
      {actor, args} = Map.pop(args, :talker)
      {:ok, %{conversation: Conversations.create_conversation!(args, actor: actor)}}
    end)

    produce(:conversation)
  end

  command :create_profile do
    param(:talker, entity: :talker)
    param(:first_name, generate: &Faker.Person.first_name/0)
    param(:last_name, generate: &Faker.Person.last_name/0)
    param(:nickname, generate: &Faker.Person.first_name/0)

    resolve(fn args ->
      {actor, args} = Map.pop(args, :talker)
      {:ok, %{profile: Conversations.create_profile!(args, actor: actor)}}
    end)

    produce(:profile)
  end

  command :update_profile do
    resolve(fn args ->
      Conversations.update_profile(actor: args.talker)
    end)

    update(:profile)
  end

  command :send_message do
    param(:conversation, entity: :conversation)
    param(:content, generate: &Faker.Lorem.paragraph/0)
    param(:talker, entity: :talker)

    resolve(fn args ->
      {actor, args} = Map.pop(args, :talker)
      {conversation, args} = Map.pop(args, :conversation)

      args =
        Map.put(args, :conversation_id, conversation.id)

      {:ok, %{message: Conversations.send_message!(args, actor: actor)}}
    end)

    produce(:message)
  end

  # command :mark_message_as_read do
  #   resolve(fn args ->
  #     Conversations.mark_message_as_read(actor: args.talker)
  #   end)

  #   produce(:message)
  # end
end
