defmodule Smalltalk.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Smalltalk.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  require Logger

  using do
    quote do
      alias Smalltalk.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Smalltalk.DataCase
      import Assertions
    end
  end

  setup tags do
    Smalltalk.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Smalltalk.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Checks Ash errors for containing a message.

  Helpful for fuzzy searching error responses. Avoids over-concern with meticulously creating
  sample date to test for specific error messages.
  """
  def errors_contain?({:ok, value}, _msg),
    do:
      raise("""
      Not an error value

      #{inspect(value)}
      """)

  def errors_contain?({:error, ash_error}, msg), do: errors_contain?(ash_error, msg)

  def errors_contain?(ash_error, msg) do
    ash_error
    |> Ash.Error.error_descriptions()
    |> String.contains?(msg) ||
      raise """
      Expected Message Not Found

      Expected Message:

      #{msg}

      Errors:

      #{Ash.Error.error_descriptions(ash_error)}
      """
  end

  def set_logger_level_info(_context) do
    initial_logger_level = Application.fetch_env!(:logger, :level)
    Logger.configure(level: :info)

    on_exit(fn -> Logger.configure(level: initial_logger_level) end)
  end

  def start_s3_container(_context) do
    starting_bucket = "test"
    bind_mount_local_path = Path.join(File.cwd!(), "test/support/s3mock")
    bind_mount_container_path = "containers3root"

    config =
      %Testcontainers.Container{image: "adobe/s3mock:latest"}
      |> Testcontainers.Container.with_environment("initialBuckets", starting_bucket)
      |> Testcontainers.Container.with_environment("root", bind_mount_container_path)
      |> Testcontainers.Container.with_environment("debug", "true")
      |> Testcontainers.Container.with_exposed_ports([9090, 9191])
      |> Testcontainers.Container.with_bind_mount(
        bind_mount_local_path,
        "/#{bind_mount_container_path}"
      )

    {:ok, container} = Testcontainers.start_container(config)

    Testcontainers.Container.with_waiting_strategy(
      container,
      Testcontainers.PortWaitStrategy.new(container.ip_address, 9090)
    )

    ExUnit.Callbacks.on_exit(fn ->
      ExAws.S3.list_objects(starting_bucket)
      |> ExAws.request!()

      Testcontainers.stop_container(container.container_id)
    end)

    %{container: container, starting_bucket: starting_bucket}
  end

  def delete_all_bucket_objects(context, bucket \\ nil) do
    bucket = bucket || context.starting_bucket

    keys =
      bucket
      |> ExAws.S3.list_objects()
      |> ExAws.stream!()
      |> Enum.map(& &1.key)

    if Enum.any?(keys) do
      ExAws.S3.delete_all_objects(bucket, keys)
      |> ExAws.request()
    end

    :ok
  end
end
