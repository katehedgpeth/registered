defmodule RegisteredTest do
  use ExUnit.Case
  doctest Registered

  test "greets the world" do
    assert Registered.hello() == :world
  end
end
