defmodule EmergencySystem.DataTest do
  use ExUnit.Case

  alias EmergencySystem.Data

  test "initial_state creates the main data structures" do
    state = Data.initial_state()

    assert is_map(state)
    assert state.users == %{}
    assert state.zones == %{}
    assert state.needs == %{}
    assert state.resources == %{}
    assert state.messages == []
    assert MapSet.size(state.active_users) == 0
    assert is_list(state.activity_log)
  end

  test "creates a zone with empty sectors" do
    zone = Data.new_zone("Z001", "Zona Norte", :critical, 200)

    assert zone.code == "Z001"
    assert zone.name == "Zona Norte"
    assert zone.impact_level == :critical
    assert zone.sectors == %{}
  end

  test "creates a sector with empty attention points" do
    sector = Data.new_sector("S001", "Sector 1", 100)

    assert sector.code == "S001"
    assert sector.affected_people == 100
    assert sector.attention_points == %{}
  end

  test "creates an attention point" do
    point =
      Data.new_attention_point(
        "P001",
        "Puesto de salud",
        "Atención de primeros auxilios"
      )

    assert point.code == "P001"
    assert point.name == "Puesto de salud"
  end
end
