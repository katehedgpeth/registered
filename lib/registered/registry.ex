defmodule Registered.Registry do
  require Logger

  defmodule AlreadyRegisteredError do
    defexception [:existing, :name]

    def message(%__MODULE__{} = ex) do
      "Registry already saved in process as #{inspect(ex.existing)} (attempted to save as #{ex.name})"
    end
  end

  defp default(opts) do
    opts
    |> Keyword.fetch!(:otp_app)
    |> Application.fetch_env!(Registered)
    |> Keyword.fetch!(:registry_name)
  end

  def child_spec(opts) do
    opts =
      Keyword.put_new_lazy(opts, :name, fn ->
        get(default: default(opts))
      end)

    :ok = save!(opts)

    Supervisor.child_spec({Registry, opts}, start: {__MODULE__, :start_link, [opts]})
  end

  def start_link(name: name) do
    with {:ok, pid} <- Registry.start_link(name: name, keys: :unique) do
      :ok = save!(name: name)
      {:ok, pid}
    end
  end

  defp save!(opts) do
    name = Keyword.fetch!(opts, :name)

    if is_nil(name) or not is_atom(name) do
      raise "expected registry name to be an atom, got: #{inspect(name)}"
    end

    case get() do
      {:error, :not_found} ->
        nil = Process.put(key(), name)

        Logger.debug("Registry saved to process #{inspect(self())}: #{inspect(name)}")

      {:ok, ^name} ->
        :ok

      {:ok, other} ->
        raise AlreadyRegisteredError.exception(existing: other, name: name)
    end
  end

  def get(opts \\ [], from \\ self()) do
    with nil <- ProcessTree.get_from(from, key()),
         nil <- Keyword.get(opts, :default) do
      {:error, :not_found}
    else
      name when is_atom(name) -> {:ok, name}
    end
  end

  def get!() do
    case get() do
      {:ok, name} -> name
      {:error, :not_found} -> raise "[#{__MODULE__}] Registry not saved in process!"
    end
  end

  defp key() do
    {__MODULE__, :name}
  end

  def key(Registered.IsolatedCase), do: key()
end
