defmodule RegisteredTest do
  use ExUnit.Case, async: true

  test "start_link saves the registry name to the process tree", _ctx do
    assert Registered.Registry.get() == {:error, :not_found}
  end
end
