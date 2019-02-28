defmodule PhoenixTest do
  use ExUnit.Case
  doctest Phoenix

  test "greets the world" do
    assert Phoenix.hello() == :world
  end
end
