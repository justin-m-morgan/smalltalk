defmodule SmalltalkWeb.Live.Accounts.RegisterLiveTest do
  use SmalltalkWeb.ConnCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  @register_form_selector "#user-password-register-with-password-wrapper form"

  describe "register account" do
    setup do
      form_params = %{
        user: %{
          email: Faker.Internet.email(),
          password: "password",
          password_confirmation: "password"
        }
      }

      %{form_params: form_params}
    end

    test "succeeds with valid credentials", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/register])

      assert {:ok, conn} =
               view
               |> form(@register_form_selector, context.form_params)
               |> render_submit()
               |> follow_redirect(conn)

      assert conn.path_info == ["auth", "user", "password", "sign_in_with_token"]
    end

    test "exposes error if passwords do not match", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/register])

      form_params =
        put_in(context.form_params, [:user, :password_confirmation], "not_the_same_password")

      view
      |> form(@register_form_selector, form_params)
      |> render_submit()

      assert view |> element(~s([phx-feedback-for="user[password_confirmation]"])) |> render() =~
               "does not match"
    end

    test "exposes error if email already taken", %{conn: conn} = context do
      %{user: user} = produce(context, [:user])

      form_params =
        put_in(context.form_params, [:user, :email], user.email)

      {:ok, view, _html} = live(conn, ~p[/register])

      view
      |> form(@register_form_selector, form_params)
      |> render_submit()

      assert view |> element(~s([phx-feedback-for="user[email]"])) |> render() =~
               "already been taken"
    end
  end
end
