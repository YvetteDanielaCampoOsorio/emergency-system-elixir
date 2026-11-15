defmodule EmergencySystemTest do
  use ExUnit.Case

  test "el módulo principal está definido" do
    assert Code.ensure_loaded?(EmergencySystem)
  end
end
