defmodule Registered.SupervisorTest do
  use Registered.IsolatedCase

  alias Registered.SupervisorUnderTest.WithoutUnique
  alias Registered.SupervisorUnderTest.WithUnique

  describe "without unique args" do
    test "can only start one process per registry", ctx do
      assert {:ok, pid} = WithoutUnique.start_link(test_pid: self())

      assert_receive {WithoutUnique, :hello, ^pid}
      name_1 = WithoutUnique.name!()
      assert name_1 == {:via, Registry, {ctx.registry, {WithoutUnique, []}}}

      # assert that we cannot start a second process with the same spec
      assert WithoutUnique.start_link(test_pid: ProcessTree.parent(self())) ==
               {:error, {:already_started, pid}}

      assert WithoutUnique.whereis!() == pid

      r2 = Module.concat(ctx.registry, Number2)

      # Delete the registry from the process dictionary and start a new one
      # (which will save itself to the process dict)
      # NOTE: delete!/1 is only available in the test environment - it's not meant to be used in prod
      assert :ok = Registered.IsolatedCase.delete_registry!(ctx.registry)
      assert Registered.Registry.get() == {:error, :not_found}
      assert Registered.Registry.get([], ctx.registry) == {:error, :not_found}
      assert {:ok, _pid} = Registered.Registry.start_link(name: r2)
      # validate that the new process name was saved
      assert Registered.Registry.get() == {:ok, r2}

      # assert that we can start a second process with the same spec now b/c we're using a different registry
      assert {:ok, new} = WithoutUnique.start_link(test_pid: self())
      assert WithoutUnique.whereis!() == new
      assert WithoutUnique.name!() == {:via, Registry, {r2, {WithoutUnique, []}}}

      # assert that the original process is still around because its registry is still running
      assert GenServer.whereis(name_1) == pid
    end
  end

  describe "with unique args" do
    test "can only start one process per unique argument", ctx do
      opts = [test_pid: self(), number: 1, foo: :bar]
      assert {:ok, pid} = WithUnique.start_link(opts)

      assert_receive {WithUnique, :hello, {^pid, ^opts}}
      name_1 = WithUnique.name!(opts)
      assert name_1 == {:via, Registry, {ctx.registry, {WithUnique, [number: 1]}}}

      # assert that we cannot start a second process with the same unique option,
      # even with a different value for a non-unique option
      assert WithUnique.start_link(Keyword.replace!(opts, :foo, :baz)) ==
               {:error, {:already_started, pid}}

      refute_receive _

      # assert that we can start a second process with a different unique option
      opts_2 = Keyword.replace!(opts, :number, 2)
      assert {:ok, pid2} = WithUnique.start_link(opts_2)
      assert_receive {WithUnique, :hello, {^pid2, ^opts_2}}
      refute pid2 == pid

      assert WithUnique.name!(opts_2) ==
               {:via, Registry, {ctx.registry, {WithUnique, number: 2}}}

      assert WithUnique.whereis!(opts) == pid
      assert WithUnique.whereis!(opts_2) == pid2
    end
  end
end
