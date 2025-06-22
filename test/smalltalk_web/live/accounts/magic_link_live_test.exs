defmodule SmalltalkWeb.Live.Accounts.MagicLinkLiveTest do
  use SmalltalkWeb.ConnCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  import Swoosh.TestAssertions

  @sign_in_form_selector ~s(form[action="/auth/user/magic_link/request?"])

  describe "magic link" do
    setup %{conn: conn} do
      form_params = %{
        user: %{
          email: "email@email.com"
        }
      }

      {:ok, view, _html} = live(conn, ~p[/sign-in])

      assert view
             |> form(@sign_in_form_selector, form_params)
             |> render_submit()

      %{view: view, form_params: form_params}
    end

    test "alerts user to check email", context do
      assert context.view
             |> element(~s([role="alert"]))
             |> render() =~ "If this user exists in our database"
    end

    test "sends email", context do
      assert_email_sent(fn email ->
        expected_email = context.form_params.user.email

        assert email.subject == "Your login link"
        assert [{"", ^expected_email}] = email.to
      end)
    end
  end
end
