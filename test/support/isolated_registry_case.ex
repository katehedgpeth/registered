defmodule Registered.IsolatedCase do
  use ExUnit.CaseTemplate

  using ctx do
    ctx = Keyword.put_new(ctx, :async, true)

    quote do
      use ExUnit.Case, unquote(ctx)
    end
  end

  setup ctx do
    Registered.IsolatedCase.setup!(ctx)
  end

  def setup!(ctx) do
    name = Module.concat(__MODULE__, ctx.test)
    assert {:ok, pid} = Registered.Registry.start_link(name: name)
    assert Registered.Registry.get() == {:ok, name}
    assert Registered.Registry.get([], pid) == {:ok, name}

    Map.put(ctx, :registry, name)
  end

  def delete_registry!(current) do
    ^current = Process.delete(key())

    :ok
  end

  def switch_registry!(from, to) do
    ^from = Process.put(key(), to)

    :ok
  end

  def key(), do: Registered.Registry.key(__MODULE__)
end
