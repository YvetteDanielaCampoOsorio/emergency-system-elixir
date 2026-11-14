
defmodule EmergencySystem.Shelters.ShelterManagerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Shelters.ShelterManager
  alias EmergencySystem.People.PersonManager

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

  defp state_with_shelter_and_person(capacity \\ 2) do
    state = state_with_zone()

    {:ok, state, _person} =
      PersonManager.register_person(
        state,
        "P001",
        "Andres",
        "123456",
        25,
        "Z001",
        :located
      )

    {:ok, state, _shelter} =
      ShelterManager.register_shelter(
        state,
        "A001",
        "Albergue central",
        "Z001",
        capacity
      )

    state
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

  # ============================================================
  # PRUEBAS DE INGRESOS
  # ============================================================

  describe "register_entry/3" do
    test "registra correctamente el ingreso de una persona" do
      state = state_with_shelter_and_person()

      assert {:ok, updated_state, shelter, person} =
               ShelterManager.register_entry(state, "A001", "123456")

      assert shelter.occupancy == 1
      assert MapSet.member?(shelter.occupants, "123456")
      assert person.status == :in_shelter
      assert updated_state.people["P001"].status == :in_shelter
    end

    test "rechaza el ingreso duplicado de una persona" do
      state = state_with_shelter_and_person()

      assert {:ok, updated_state, _shelter, _person} =
               ShelterManager.register_entry(state, "A001", "123456")

      assert {:error, :person_already_inside} =
               ShelterManager.register_entry(
                 updated_state,
                 "A001",
                 "123456"
               )
    end

    test "rechaza el ingreso cuando el albergue está lleno" do
      state = state_with_shelter_and_person(1)

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      {:ok, state, _person} =
        PersonManager.register_person(
          state,
          "P002",
          "Maria",
          "654321",
          30,
          "Z001",
          :located
        )

      assert {:error, :shelter_full} =
               ShelterManager.register_entry(state, "A001", "654321")
    end

    test "rechaza el ingreso de una persona inexistente" do
      state = state_with_shelter_and_person()

      assert {:error, :person_not_found} =
               ShelterManager.register_entry(state, "A001", "999999")
    end
  end

  # ============================================================
  # PRUEBAS DE SALIDAS
  # ============================================================

  describe "register_exit/4" do
    test "registra la salida de una persona trasladada" do
      state = state_with_shelter_and_person()

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      assert {:ok, updated_state, shelter, person} =
               ShelterManager.register_exit(
                 state,
                 "A001",
                 "123456",
                 :transferred
               )

      assert shelter.occupancy == 0
      refute MapSet.member?(shelter.occupants, "123456")
      assert person.status == :transferred
      assert updated_state.people["P001"].status == :transferred
    end

    test "registra la salida de una persona reunificada" do
      state = state_with_shelter_and_person()

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      assert {:ok, _updated_state, shelter, person} =
               ShelterManager.register_exit(
                 state,
                 "A001",
                 "123456",
                 :reunified
               )

      assert shelter.occupancy == 0
      assert person.status == :reunified
    end

    test "rechaza la salida de una persona que no está en el albergue" do
      state = state_with_shelter_and_person()

      assert {:error, :person_not_in_shelter} =
               ShelterManager.register_exit(
                 state,
                 "A001",
                 "123456",
                 :transferred
               )
    end

    test "rechaza un estado de destino inválido" do
      state = state_with_shelter_and_person()

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      assert {:error, :invalid_destination_status} =
               ShelterManager.register_exit(
                 state,
                 "A001",
                 "123456",
                 :located
               )
    end
  end

  # ============================================================
  # PRUEBAS DE CAPACIDAD
  # ============================================================

  describe "available_capacity/2" do
    test "devuelve todos los cupos cuando el albergue está vacío" do
      state = state_with_shelter_and_person(10)

      assert {:ok, 10} =
               ShelterManager.available_capacity(state, "A001")
    end

    test "actualiza los cupos después de un ingreso" do
      state = state_with_shelter_and_person(10)

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      assert {:ok, 9} =
               ShelterManager.available_capacity(state, "A001")
    end

    test "devuelve los cupos después de una salida" do
      state = state_with_shelter_and_person(10)

      {:ok, state, _shelter, _person} =
        ShelterManager.register_entry(state, "A001", "123456")

      {:ok, state, _shelter, _person} =
        ShelterManager.register_exit(
          state,
          "A001",
          "123456",
          :reunified
        )

      assert {:ok, 10} =
               ShelterManager.available_capacity(state, "A001")
    end

    test "consulta la información completa del albergue" do
      state = state_with_shelter_and_person(10)

      assert {:ok, shelter} =
               ShelterManager.check_shelter(state, "A001")

      assert shelter.capacity == 10
      assert shelter.occupancy == 0
      assert shelter.available_capacity == 10
    end
  end

end
