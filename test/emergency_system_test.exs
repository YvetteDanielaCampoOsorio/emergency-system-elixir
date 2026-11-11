defmodule EmergencySystemTest do
  use ExUnit.Case
  doctest EmergencySystem

  test "greets the world" do
    assert EmergencySystem.hello() == :world
  end
end
