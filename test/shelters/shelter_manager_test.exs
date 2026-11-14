
defmodule EmergencySystem.Shelters.ShelterManagerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Shelters.ShelterManager

  # ESTADO DE PRUEBA

  defp state_with_zone do
    state = Data.initial_state()

    zones = %{
      "Z001" => %{
        code: "Z001",
        name: "Zona norte"
      }
    }

    %{state | zones: zones}
  end

  # PRUEBAS DE REGISTRO

  describe "register_shelter/5" do
    test "registra un albergue correctamente" do
      state = state_with_zone()

      assert {:ok, updated_state, shelter} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z001",
                 100
               )

      assert shelter.code == "A001"
      assert shelter.name == "Albergue central"
      assert shelter.zone_code == "Z001"
      assert shelter.capacity == 100
      assert shelter.occupancy == 0

      assert Map.has_key?(updated_state.shelters, "A001")
    end

    test "rechaza un código de albergue duplicado" do
      state = state_with_zone()

      assert {:ok, state, _shelter} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z001",
                 100
               )

      assert {:error, :duplicate_shelter} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Otro albergue",
                 "Z001",
                 50
               )
    end

    test "rechaza una zona inexistente" do
      state = state_with_zone()

      assert {:error, :zone_not_found} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z999",
                 100
               )
    end

    test "rechaza una capacidad negativa" do
      state = state_with_zone()

      assert {:error, :invalid_capacity} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z001",
                 -10
               )
    end

    test "rechaza campos vacíos" do
      state = state_with_zone()

      assert {:error, :invalid_fields} =
               ShelterManager.register_shelter(
                 state,
                 "",
                 "Albergue central",
                 "Z001",
                 100
               )
    end

    test "rechaza un estado inválido" do
      assert {:error, :invalid_state} =
               ShelterManager.register_shelter(
                 %{},
                 "A001",
                 "Albergue central",
                 "Z001",
                 100
               )
    end
  end

  # PRUEBAS DE CONSULTA

  describe "list_shelters/1" do
    test "devuelve todos los albergues registrados" do
      state = state_with_zone()

      assert {:ok, state, _shelter} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z001",
                 100
               )

      assert {:ok, shelters} = ShelterManager.list_shelters(state)

      assert length(shelters) == 1
      assert hd(shelters).code == "A001"
    end

    test "devuelve una lista vacía cuando no hay albergues" do
      state = state_with_zone()

      assert {:ok, []} = ShelterManager.list_shelters(state)
    end

    test "rechaza un estado inválido" do
      assert {:error, :invalid_state} =
               ShelterManager.list_shelters(%{})
    end
  end

  describe "get_shelter/2" do
    test "encuentra un albergue por su código" do
      state = state_with_zone()

      assert {:ok, state, _shelter} =
               ShelterManager.register_shelter(
                 state,
                 "A001",
                 "Albergue central",
                 "Z001",
                 100
               )

      assert {:ok, shelter} =
               ShelterManager.get_shelter(state, "A001")

      assert shelter.name == "Albergue central"
    end

    test "devuelve error cuando el albergue no existe" do
      state = state_with_zone()

      assert {:error, :shelter_not_found} =
               ShelterManager.get_shelter(state, "A999")
    end

    test "rechaza un código vacío" do
      state = state_with_zone()

      assert {:error, :invalid_code} =
               ShelterManager.get_shelter(state, "")
    end
  end
end
