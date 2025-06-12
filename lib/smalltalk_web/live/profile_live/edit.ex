defmodule SmalltalkWeb.ProfileLive.Edit do
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    form = form(actor, %{})

    socket =
      assign(socket,
        actor: actor,
        form: form
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", params, socket) do
    params = Map.get(params, socket.assigns.form.name)
    original_form = socket.assigns.form

    socket = assign(socket, form: AshPhoenix.Form.validate(original_form, params))

    {:noreply, socket}
  end

  def handle_event("save_profile", params, socket) do
    actor = socket.assigns.actor

    params = Map.get(params, socket.assigns.form.name)
    original_form = socket.assigns.form

    socket =
      case AshPhoenix.Form.submit(original_form, params: params) do
        {:ok, profile} ->
          send(self(), {:profile_saved, profile})

          actor = Ash.load!(actor, [:profile], actor: actor)

          socket
          |> assign(:form, form(actor, %{}))
          |> put_flash(:success, "Profile Updated")

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:profile}
      active_sub_tab={:edit_details}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Profile
      </Containers.header>

      <div class="grid gap-4">
        <Containers.card container_class="mx-auto max-w-2xl bg-base-200 shadow-xl">
          <Forms.simple_form form={@form} phx-change="validate_profile" phx-submit="save_profile">
            <div class="grid lg:grid-cols-2 gap-4">
              <Forms.text_input field={@form[:first_name]} label="First Name" />
              <Forms.text_input field={@form[:last_name]} label="Last Name" />
              <Forms.text_input field={@form[:nickname]} label="Nickname (Optional)" />
              <Forms.text_input field={@form[:age]} label="Age" />
              <Forms.text_input field={@form[:location]} label="Location" />
              <Forms.text_input field={@form[:relationship_status]} label="Relationship Status" />
              <Forms.text_input
                field={@form[:profession]}
                label="Profession"
                container_class="col-span-full"
              />
              <Forms.text_input
                field={@form[:education]}
                label="Education"
                container_class="col-span-full"
              />
              <Forms.text_input
                field={@form[:hobbies]}
                label="Hobbies"
                container_class="col-span-full"
              />
            </div>
          </Forms.simple_form>
        </Containers.card>
      </div>
    </Layouts.app>
    """
  end

  defp form(%{profile: %Conversations.Profile{} = profile} = actor, params) do
    profile
    |> Conversations.form_to_update_profile(params: params, actor: actor, as: "profile")
    |> to_form()
  end

  defp form(%{profile: nil} = actor, params) do
    [params: params, actor: actor, as: "profile"]
    |> Conversations.form_to_create_profile()
    |> to_form()
  end
end
