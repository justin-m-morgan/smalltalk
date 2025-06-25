defmodule SmalltalkWeb.Components.Profile.ImageUpload do
  use SmalltalkWeb, :live_component

  alias Smalltalk.Conversations
  alias Smalltalk.Uploads.ImageProcessor

  require Logger

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    accepted_file_types = ~w(.jpg .jpeg)
    max_file_size = 6_000_000

    socket =
      socket
      |> assign(assigns)
      |> assign(
        uploaded_files: [],
        accepted_file_types: accepted_file_types,
        max_file_size: max_file_size
      )
      |> allow_upload(assigns.upload_key,
        accept: accepted_file_types,
        max_entries: assigns[:max_entries] || 1,
        max_file_size: max_file_size
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", _params, socket) do
    actor = socket.assigns.actor
    self = self()

    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        s3_path =
          ImageProcessor.upload_original_image(path, actor.user_id)

        Conversations.submit_profile_pic!(%{original_src: s3_path}, actor: actor)

        send(self, :image_saved)

        {:ok, s3_path}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(error), do: Logger.error(error)

  @impl Phoenix.LiveComponent

  attr :uploads, :map, required: true
  attr :upload_key, :map, required: true

  def render(assigns) do
    ~H"""
    <section>
      <div class="grid gap-4">
        <%!-- render each avatar entry --%>

        <div phx-drop-target={@uploads[@upload_key].ref} class="flex flex-col items-center gap-2">
          <.dropzone accepted_file_types={@accepted_file_types} max_file_size={@max_file_size} />
          <.upload_form target={@myself} upload_config={@uploads[@upload_key]} />
        </div>
        <div class="grid grid-cols-3 lg:grid-cols-4 gap-4">
          <div class="only:flex justify-center items-center h-full hidden ">
            <p class="text-xl font-bold">No Files Provided</p>
          </div>
          <Containers.card :for={entry <- @uploads[@upload_key].entries} container_class="bg-base-200">
            <.upload_entry upload_config={@uploads[@upload_key]} entry={entry} target={@myself} />
          </Containers.card>
        </div>
      </div>

      <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
      <p :for={err <- upload_errors(@uploads[@upload_key])} class="alert alert-warning">
        <Icon.icon name="hero-exclamation-triangle-solid" class="size-8" />
        {error_to_string(err)}
      </p>
    </section>
    """
  end

  attr :accepted_file_types, :list
  attr :max_file_size, :string

  defp dropzone(assigns) do
    ~H"""
    <div class="flex items-center justify-center w-full">
      <label
        for="dropzone-file"
        class={[
          "flex flex-col items-center justify-center ",
          "rounded-lg bg-base-200  hover:bg-base-200/50 transition-all",
          "w-full h-64 cursor-pointer",
          "border-2 border-gray-300 border-dashed"
        ]}
      >
        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <Icon.icon name="hero-cloud-arrow-up" class="size-12" />
          <p class="mb-2 text-sm">
            <span class="font-semibold">Click to upload</span> or drag and drop
          </p>
          <p class="text-xs">
            {Enum.join(@accepted_file_types, ", ")} (Max File Size: {Float.round(
              @max_file_size / 1_000_000,
              1
            )} MB)
          </p>
        </div>
        <input id="dropzone-file" type="file" class="hidden" />
      </label>
    </div>
    """
  end

  attr :upload_config, Phoenix.LiveView.UploadConfig, required: true
  attr :target, :any, required: true

  def upload_form(assigns) do
    ~H"""
    <form
      id="upload-form"
      phx-submit="save"
      phx-target={@target}
      phx-change="validate"
      class="w-full flex gap-2"
    >
      <.live_file_input upload={@upload_config} class="file-input file-input-primary grow-1" />
      <Button.button
        disabled={not Enum.any?(@upload_config.entries) || Enum.any?(upload_errors(@upload_config))}
        type="submit"
      >
        Upload
      </Button.button>
    </form>
    """
  end

  attr :upload_config, Phoenix.LiveView.UploadConfig, required: true
  attr :entry, Phoenix.LiveView.UploadEntry, required: true
  attr :target, :any, required: true

  @spec upload_entry(map()) :: Phoenix.LiveView.Rendered.t()
  def upload_entry(assigns) do
    ~H"""
    <article class="upload-entry">
      <figure class="flex flex-col items-center">
        <.live_img_preview entry={@entry} class="h-48 object-contain" />
        <div>
          <figcaption>{@entry.client_name}</figcaption>
          <div>
            <%!-- entry.progress will update automatically for in-flight entries --%>
            <progress value={@entry.progress} max="100">{@entry.progress}%</progress>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-target={@target}
              phx-value-ref={@entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
          </div>
          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
          <p :for={err <- upload_errors(@upload_config, @entry)} class="alert alert-error">
            <Icon.icon name="hero-exclamation-triangle-solid" class="size-8" />
            {error_to_string(err)}
          </p>
        </div>
      </figure>

      <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
    </article>
    """
  end
end
