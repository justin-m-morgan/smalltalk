defmodule Smalltalk.Accounts do
  use Ash.Domain,
    otp_app: :smalltalk

  resources do
    resource Smalltalk.Accounts.Token
    resource Smalltalk.Accounts.User
  end
end
