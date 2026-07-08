defmodule Registered.Process do
  defmodule NotFoundError do
    defexception [:opts, :name]

    def message(%__MODULE__{} = ex) do
      "service not found: #{inspect(ex, pretty: true)}"
    end
  end

  defmacro __using__(opts) do
    {as, as_opts} = Keyword.fetch!(opts, :as)

    unique = Keyword.get(opts, :unique, [])

    quote do
      @as unquote(as)
      if Kernel.macro_exported?(@as, :__using__, 1) do
        use unquote(as), unquote(as_opts)
      end

      def child_spec(opts) do
        as_opts = Keyword.put(unquote(as_opts), :name, name!(opts))

        Supervisor.child_spec({@as, as_opts},
          start: {__MODULE__, :start_link, [opts]},
          id: {__MODULE__, Keyword.take(opts, unquote(unique))}
        )
      end

      cond do
        Kernel.function_exported?(@as, :start_link, 3) ->
          def start_link(opts) do
            @as.start_link(__MODULE__, opts, name: name!(opts))
          end

        Kernel.function_exported?(@as, :start_link, 1) ->
          def start_link(opts) do
            opts
            |> Keyword.put(:name, name!(opts))
            |> @as.start_link()
          end

        true ->
          def start_link(opts) do
            {:error, {:not_defined, {:start_link, opts}}}
          end
      end

      defoverridable(start_link: 1)

      def name!(opts) do
        {:via, Registry,
         {Registered.Registry.get!(), {__MODULE__, Keyword.take(opts, unquote(unique))}}}
      end

      def whereis(opts) do
        opts
        |> name!()
        |> GenServer.whereis()
        |> case do
          nil ->
            {:error, Registered.Process.NotFoundError.exception(opts: opts, name: name!(opts))}

          pid when is_pid(pid) ->
            {:ok, pid}
        end
      end

      def whereis!(opts) do
        case whereis(opts) do
          {:ok, pid} ->
            pid

          {:error, error} ->
            raise error
        end
      end

      if unquote(unique) == [] do
        def name!(), do: name!([])
        def whereis(), do: whereis([])
        def whereis!(), do: whereis!([])
      end

      if @as in [Supervisor, DynamicSupervisor] do
        def start_child!(spec, opts) when is_tuple(spec) or is_map(spec) do
          opts
          |> whereis!()
          |> Supervisor.start_child(spec)
        end
      end

      if @as == GenServer do
        @spec cast(request :: term(), opts :: Keyword.t()) :: :ok
        def cast(request, opts) do
          opts
          |> name!()
          |> GenServer.cast(request)
        end

        @spec call(
                request :: term(),
                timeout :: integer | :infinity,
                opts :: Keyword.t()
              ) :: term()
        def call(request, timeout \\ 5_000, opts) do
          opts
          |> name!()
          |> GenServer.call(request, timeout)
        end
      end
    end
  end
end
