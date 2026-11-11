defmodule EmergencySystem.Zones.ZoneManagerTest do
  use ExUnit.Case

  alias EmergencySystem.Data
  alias EmergencySystem.Zones.ZoneManager

  setup do
    %{state: Data.initial_state()}
  end

  describe "create_zone/5" do
    test "registra una zona correctamente", %{state: state} do
      assert {:ok, updated_state, zone} =
               ZoneManager.create_zone(state, "Z001", "Centro", :high, 250)

      assert Map.has_key?(updated_state.zones, "Z001")
      assert zone.name == "Centro"
      assert zone.impact_level == :high
      assert zone.estimated_people == 250
    end

    test "rechaza una zona con código duplicado", %{state: state} do
      assert {:ok, updated_state, _zone} =
               ZoneManager.create_zone(state, "Z001", "Centro", :high, 250)

      assert {:error, :zone_already_exists} =
               ZoneManager.create_zone(updated_state, "Z001", "Norte", :low, 100)
    end

    test "rechaza un nivel de afectación inválido", %{state: state} do
      assert {:error, :invalid_impact_level} =
               ZoneManager.create_zone(state, "Z001", "Centro", :extreme, 250)
    end

    test "rechaza una cantidad negativa de personas", %{state: state} do
      assert {:error, :invalid_people_count} =
               ZoneManager.create_zone(state, "Z001", "Centro", :high, -10)
    end

    test "rechaza nombres vacíos", %{state: state} do
      assert {:error, :empty_fields} =
               ZoneManager.create_zone(state, "Z001", " ", :high, 250)
    end

    test "rechaza argumentos inválidos", %{state: state} do
      assert {:error, :invalid_arguments} =
               ZoneManager.create_zone(state, 123, "Centro", :high, 250)
    end
  end

  describe "add_sector/5" do
    setup %{state: state} do
      assert {:ok, state_with_zone, _zone} =
               ZoneManager.create_zone(state, "Z001", "Centro", :high, 250)

      %{state: state_with_zone}
    end

    test "agrega un sector a una zona existente", %{state: state} do
      assert {:ok, updated_state, sector} =
               ZoneManager.add_sector(state, "Z001", "S001", "Sector Norte", 100)

      assert Map.has_key?(updated_state.zones["Z001"].sectors, "S001")
      assert sector.name == "Sector Norte"
      assert sector.affected_people == 100
    end

    test "rechaza una zona inexistente", %{state: state} do
      assert {:error, :zone_not_found} =
               ZoneManager.add_sector(state, "Z999", "S001", "Norte", 100)
    end

    test "rechaza un sector duplicado", %{state: state} do
      assert {:ok, updated_state, _sector} =
               ZoneManager.add_sector(state, "Z001", "S001", "Norte", 100)

      assert {:error, :sector_already_exists} =
               ZoneManager.add_sector(updated_state, "Z001", "S001", "Sur", 50)
    end

    test "rechaza cantidades negativas", %{state: state} do
      assert {:error, :invalid_people_count} =
               ZoneManager.add_sector(state, "Z001", "S001", "Norte", -10)
    end

    test "rechaza nombres vacíos", %{state: state} do
      assert {:error, :empty_fields} =
               ZoneManager.add_sector(state, "Z001", "S001", " ", 100)
    end

    test "rechaza argumentos inválidos", %{state: state} do
      assert {:error, :invalid_arguments} =
               ZoneManager.add_sector(state, "Z001", 123, "Norte", 100)
    end
  end

  describe "add_attention_point/6" do
    setup %{state: state} do
      assert {:ok, state_with_zone, _zone} =
               ZoneManager.create_zone(state, "Z001", "Centro", :high, 250)

      assert {:ok, state_with_sector, _sector} =
               ZoneManager.add_sector(
                 state_with_zone,
                 "Z001",
                 "S001",
                 "Sector Norte",
                 100
               )

      %{state: state_with_sector}
    end

    test "agrega un punto de atención correctamente", %{state: state} do
      assert {:ok, updated_state, point} =
               ZoneManager.add_attention_point(
                 state,
                 "Z001",
                 "S001",
                 "P001",
                 "Primeros auxilios",
                 "Atención médica básica"
               )

      assert Map.has_key?(
               updated_state.zones["Z001"].sectors["S001"].attention_points,
               "P001"
             )

      assert point.name == "Primeros auxilios"
      assert point.description == "Atención médica básica"
    end

    test "rechaza una zona inexistente", %{state: state} do
      assert {:error, :zone_not_found} =
               ZoneManager.add_attention_point(
                 state,
                 "Z999",
                 "S001",
                 "P001",
                 "Auxilios",
                 "Atención médica"
               )
    end

    test "rechaza un sector inexistente", %{state: state} do
      assert {:error, :sector_not_found} =
               ZoneManager.add_attention_point(
                 state,
                 "Z001",
                 "S999",
                 "P001",
                 "Auxilios",
                 "Atención médica"
               )
    end

    test "rechaza puntos duplicados", %{state: state} do
      assert {:ok, updated_state, _point} =
               ZoneManager.add_attention_point(
                 state,
                 "Z001",
                 "S001",
                 "P001",
                 "Auxilios",
                 "Atención médica"
               )

      assert {:error, :point_already_exists} =
               ZoneManager.add_attention_point(
                 updated_state,
                 "Z001",
                 "S001",
                 "P001",
                 "Otro",
                 "Otra descripción"
               )
    end

    test "rechaza descripciones vacías", %{state: state} do
      assert {:error, :empty_fields} =
               ZoneManager.add_attention_point(
                 state,
                 "Z001",
                 "S001",
                 "P001",
                 "Auxilios",
                 " "
               )
    end

    test "rechaza argumentos inválidos", %{state: state} do
      assert {:error, :invalid_arguments} =
               ZoneManager.add_attention_point(
                 state,
                 "Z001",
                 "S001",
                 123,
                 "Auxilios",
                 "Atención médica"
               )
    end
  end
end
