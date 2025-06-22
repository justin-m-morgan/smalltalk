defmodule SmalltalkWeb.Live.Accounts.SignInLiveTest do
  use SmalltalkWeb.ConnCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  @sign_in_form_selector "#user-password-sign-in-with-password-wrapper form"

  produce(:user)

  describe "sign in" do
    setup context do
      form_params = %{
        user: %{
          email: context.user.email,
          password: "password"
        }
      }

      %{form_params: form_params}
    end

    test "succeeds with valid credentials", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/sign-in])

      assert {:ok, conn} =
               view
               |> form(@sign_in_form_selector, context.form_params)
               |> render_submit()
               |> follow_redirect(conn)

      assert conn.path_info == ["auth", "user", "password", "sign_in_with_token"]
    end

    test "exposes error if password incorrect", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, ~p[/register])

      form_params = put_in(context.form_params, [:user, :password], "wrong_password")

      view
      |> form(@sign_in_form_selector, form_params)
      |> render_submit()

      assert view |> element(~s([phx-feedback-for="user[password]"])) |> render() =~
               "Email or password was incorrect"
    end
  end
end
