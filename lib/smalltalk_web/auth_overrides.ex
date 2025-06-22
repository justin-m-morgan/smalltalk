defmodule SmalltalkWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides

  # configure your UI overrides here

  # First argument to `override` is the component name you are overriding.
  # The body contains any number of configurations you wish to override
  # Below are some examples

  # For a complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html

  # override AshAuthentication.Phoenix.Components.Banner do
  #   set :image_url, "https://media.giphy.com/media/g7GKcSzwQfugw/giphy.gif"
  #   set :text_class, "bg-red-500"
  # end

  # override AshAuthentication.Phoenix.Components.SignIn do
  #  set :show_banner, false
  # end

  override AshAuthentication.Phoenix.SignInLive do
    set :root_class, "bg-primary min-h-screen"
  end

  override AshAuthentication.Phoenix.Components.Password do
    set :toggler_class, "text-primary-content"
  end

  override AshAuthentication.Phoenix.Components.HorizontalRule do
    set :text_inner_class, "text-4xl bg-base-100 rounded p-4"
    # set :text_outer_class, "bg-orange-200
  end

  override AshAuthentication.Phoenix.Components.Banner do
    set :image_url, nil
    set :dark_image_url, nil
    set :href_class, "three-d-logo"
    set :dark_href_class, "dark"
    set :text, "Smalltalk"
    set :text_class, "text-6xl font-bold"
    set :root_class, "flex flex-col items-center"
  end

  override AshAuthentication.Phoenix.Components.Password.Input do
    set :input_class, "input input-xl w-full "
    set :submit_class, "btn btn-accent btn-xl w-full"
  end
end
