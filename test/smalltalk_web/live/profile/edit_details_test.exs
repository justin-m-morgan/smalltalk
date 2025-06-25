defmodule SmalltalkWeb.Live.ProfileLive.EditTest do
  use SmalltalkWeb.ConnCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  @form_selector ~s(form[phx-submit="save_profile"])

  describe "sign in" do
    produce(:user)
    setup [:log_in_user]

    setup do
      form_params = %{
        profile: %{
          first_name: Faker.Person.first_name(),
          last_name: Faker.Person.last_name(),
          nickname: Faker.Internet.user_name()
        }
      }

      %{form_params: form_params}
    end

    test "succeeds with valid credentials", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/profile/edit])

      assert view
             |> form(@form_selector, context.form_params)
             |> render_submit()

      assert view
             |> element(~s(#flash-success))
             |> render() =~ "Profile Updated"
    end

    test "exposes error if missing required field", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/profile/edit])
      form_params = context.form_params

      form_params =
        %{form_params | profile: Map.delete(form_params.profile, :first_name)}

      view
      |> form(@form_selector, form_params)
      |> render_change()

      assert view |> element(~s([phx-feedback-for="profile[first_name]"])) |> render() =~
               "is required"
    end
  end
end
