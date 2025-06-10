defmodule SmalltalkWeb.Components.Profile.ProfileForm do
  require Logger
  use SmalltalkWeb, :live_component

  alias Smalltalk.Conversations

  require Logger

  @impl true
  def update(assigns, socket) do
    actor = assigns.talker

    form = form(actor, %{})

    socket =
      socket
      |> assign(form: form, actor: actor)

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

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Forms.simple_form
        form={@form}
        phx-change="validate_profile"
        phx-submit="save_profile"
        phx-target={@myself}
      >
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
          <Forms.text_input field={@form[:hobbies]} label="Hobbies" container_class="col-span-full" />
        </div>
      </Forms.simple_form>
    </div>
    """
  end

  defp form(%{profile: %Conversations.Profile{} = profile} = actor, params) do
    profile
    |> Conversations.form_to_update_profile(params: params, actor: actor, as: "profile")
    |> to_form()
  end

  defp form(actor, params) do
    if is_struct(actor.profile, Ash.NotLoaded) do
      Logger.warning("Profile not loaded for actor but attempting to modify it")
    end

    [params: params, actor: actor, as: "profile"]
    |> Conversations.form_to_create_profile()
    |> to_form()
  end
end
