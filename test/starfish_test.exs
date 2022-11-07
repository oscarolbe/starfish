defmodule StarfishTest do
  use ExUnit.Case
  doctest Starfish

  test "greets the world" do
    assert Starfish.hello() == :world
  end
end
