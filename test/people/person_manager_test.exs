
defmodule EmergencySystem.People.PersonManagerTest do
  use ExUnit.Case

  alias EmergencySystem.People.PersonManager

  # --------------------------------------------------
  # ESTADO DE PRUEBA
  # --------------------------------------------------


defp initial_state do
  %{
    people: %{},
    zones: %{
      "Z001" => %{code: "Z001", name: "Zona norte"},
      "Z002" => %{code: "Z002", name: "Zona sur"}
    }
  }
end


  # --------------------------------------------------
  # PRUEBAS DE REGISTRO
  # --------------------------------------------------

  test "registers a person successfully" do
    state = initial_state()

    assert {:ok, updated_state, person} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               28,
               "Z001",
               :reported
             )

    assert person.id == "P001"
    assert person.name == "Andres Rodriguez"
    assert person.reference == "1098765432"
    assert person.age == 28
    assert person.zone_code == "Z001"
    assert person.status == :reported

    assert updated_state.people["P001"] == person
  end

  test "does not register a person with a duplicated identifier" do
    state = initial_state()

    assert {:ok, updated_state, _person} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               28,
               "Z001",
               :reported
             )

    assert {:error, :duplicate_person} =
             PersonManager.register_person(
               updated_state,
               "P001",
               "Maria Lopez",
               "1098765433",
               30,
               "Z001",
               :reported
             )
  end

  test "rejects empty fields" do
    state = initial_state()

    assert {:error, :empty_fields} =
             PersonManager.register_person(
               state,
               "P001",
               "",
               "1098765432",
               28,
               "Z001",
               :reported
             )
  end

  test "rejects a negative age" do
    state = initial_state()

    assert {:error, :invalid_age} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               -5,
               "Z001",
               :reported
             )
  end

  test "rejects an invalid status" do
    state = initial_state()

    assert {:error, :invalid_status} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               28,
               "Z001",
               :unknown
             )
  end

  test "rejects a person with a nonexistent zone" do
    state = initial_state()

    assert {:error, :zone_not_found} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               28,
               "Z999",
               :reported
             )
  end

  test "rejects an invalid state structure" do
    state = %{people: [], zones: %{}}

    assert {:error, :invalid_state} =
             PersonManager.register_person(
               state,
               "P001",
               "Andres Rodriguez",
               "1098765432",
               28,
               "Z001",
               :reported
             )
  end

  # --------------------------------------------------
  # PRUEBAS DE BÚSQUEDA DE PERSONAS
  # --------------------------------------------------

  defp state_with_people do
    state = initial_state()

    {:ok, state, _person} =
      PersonManager.register_person(
        state,
        "P001",
        "Andres Rodriguez",
        "1098765432",
        28,
        "Z001",
        :reported
      )

    {:ok, state, _person} =
      PersonManager.register_person(
        state,
        "P002",
        "Maria Lopez",
        "1098765433",
        35,
        "Z001",
        :located
      )

    {:ok, state, _person} =
      PersonManager.register_person(
        state,
        "P003",
        "Carlos Perez",
        "1098765434",
        42,
        "Z002",
        :in_shelter
      )

    state
  end

  test "searches people by name using partial matches" do
    state = state_with_people()

    assert {:ok, [person]} =
             PersonManager.search_people(state, %{name: "Andres"})

    assert person.id == "P001"
  end

  test "searches people by document or reference" do
    state = state_with_people()

    assert {:ok, [person]} =
             PersonManager.search_people(
               state,
               %{document: "1098765433"}
             )

    assert person.id == "P002"
  end

  test "searches people by zone" do
    state = state_with_people()

    assert {:ok, people} =
             PersonManager.search_people(
               state,
               %{zone_code: "Z001"}
             )

    assert length(people) == 2
    assert Enum.all?(people, &(&1.zone_code == "Z001"))
  end

  test "searches people by status" do
    state = state_with_people()

    assert {:ok, [person]} =
             PersonManager.search_people(
               state,
               %{status: :located}
             )

    assert person.id == "P002"
  end

  test "combines multiple search filters" do
    state = state_with_people()

    assert {:ok, [person]} =
             PersonManager.search_people(
               state,
               %{zone_code: "Z001", status: :reported}
             )

    assert person.id == "P001"
  end

  test "returns an empty list when no person matches" do
    state = state_with_people()

    assert {:ok, []} =
             PersonManager.search_people(
               state,
               %{name: "Persona inexistente"}
             )
  end

  test "returns all people when no filters are provided" do
    state = state_with_people()

    assert {:ok, people} =
             PersonManager.search_people(state)

    assert length(people) == 3
  end

  test "rejects an invalid search filter" do
    state = state_with_people()

    assert {:error, :invalid_filters} =
             PersonManager.search_people(
               state,
               %{unknown_filter: "value"}
             )
  end

  test "rejects an invalid status filter" do
    state = state_with_people()

    assert {:error, :invalid_filters} =
             PersonManager.search_people(
               state,
               %{status: :unknown}
             )
  end

  test "rejects an invalid state structure when searching" do
    state = %{people: [], zones: %{}}

    assert {:error, :invalid_state} =
             PersonManager.search_people(state)
  end

end
