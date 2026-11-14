
defmodule EmergencySystem.Pets.PetManagerTest do
  use ExUnit.Case

  alias EmergencySystem.Pets.PetManager

  # ============================================================
  # REGISTRO DE MASCOTAS
  # ============================================================

  defp initial_state do
    %{
      pets: %{},
      zones: %{
        "Z001" => %{code: "Z001", name: "Zona norte"},
        "Z002" => %{code: "Z002", name: "Zona sur"}
      }
    }
  end

  test "registers a lost pet successfully" do
    state = initial_state()

    assert {:ok, updated_state, pet} =
             PetManager.register_pet(
               state, "PET001", :lost, "perro", "Luna",
               "Mancha blanca en el pecho", "negro",
               "mediano", "Z001", "Laura"
             )

    assert pet.id == "PET001"
    assert pet.report_type == :lost
    assert pet.species == "perro"
    assert pet.name == "Luna"
    assert pet.status == :active
    assert %DateTime{} = pet.timestamp
    assert Map.has_key?(updated_state.pets, "PET001")
  end

  test "registers a found pet successfully" do
    state = initial_state()

    assert {:ok, updated_state, pet} =
             PetManager.register_pet(
               state, "PET002", :found, "gato", nil,
               "Tiene una pata blanca", "gris",
               "pequeño", "Z002", "Carlos"
             )

    assert pet.report_type == :found
    assert pet.name == nil
    assert pet.status == :active
    assert Map.has_key?(updated_state.pets, "PET002")
  end

  test "rejects an empty pet identifier" do
    assert {:error, :invalid_id} =
             PetManager.register_pet(
               initial_state(), "", :lost, "perro", "Luna",
               "Mancha blanca", "negro", "mediano", "Z001", "Laura"
             )
  end

  test "rejects an invalid report type" do
    assert {:error, :invalid_report_type} =
             PetManager.register_pet(
               initial_state(), "PET003", :unknown, "perro", "Luna",
               "Mancha blanca", "negro", "mediano", "Z001", "Laura"
             )
  end

  test "rejects an empty species" do
    assert {:error, :invalid_species} =
             PetManager.register_pet(
               initial_state(), "PET004", :lost, "", "Luna",
               "Mancha blanca", "negro", "mediano", "Z001", "Laura"
             )
  end

  test "rejects an empty characteristics description" do
    assert {:error, :invalid_characteristics} =
             PetManager.register_pet(
               initial_state(), "PET005", :lost, "perro", "Luna",
               "", "negro", "mediano", "Z001", "Laura"
             )
  end

  test "rejects an empty color" do
    assert {:error, :invalid_color} =
             PetManager.register_pet(
               initial_state(), "PET006", :lost, "perro", "Luna",
               "Mancha blanca", "", "mediano", "Z001", "Laura"
             )
  end

  test "rejects an empty size" do
    assert {:error, :invalid_size} =
             PetManager.register_pet(
               initial_state(), "PET007", :lost, "perro", "Luna",
               "Mancha blanca", "negro", "", "Z001", "Laura"
             )
  end

  test "rejects a nonexistent zone" do
    assert {:error, :zone_not_found} =
             PetManager.register_pet(
               initial_state(), "PET008", :lost, "perro", "Luna",
               "Mancha blanca", "negro", "mediano", "Z999", "Laura"
             )
  end

  test "rejects duplicate pet identifiers" do
    state = initial_state()

    assert {:ok, state, _pet} =
             PetManager.register_pet(
               state, "PET009", :lost, "perro", "Luna",
               "Mancha blanca", "negro", "mediano", "Z001", "Laura"
             )

    assert {:error, :duplicate_pet} =
             PetManager.register_pet(
               state, "PET009", :found, "perro", nil,
               "Mancha blanca", "negro", "mediano", "Z001", "Carlos"
             )
  end

  test "does not modify the original state" do
    state = initial_state()

    assert {:ok, updated_state, _pet} =
             PetManager.register_pet(
               state, "PET010", :lost, "perro", "Luna",
               "Mancha blanca", "negro", "mediano", "Z001", "Laura"
             )

    assert state.pets == %{}
    assert map_size(updated_state.pets) == 1
  end

  # ============================================================
  # CONSULTA DE REPORTES DE MASCOTAS
  # ============================================================

  defp state_with_pets do
    state = initial_state()

    {:ok, state, _pet} =
      PetManager.register_pet(
        state, "PET020", :lost, "perro", "Luna",
        "Mancha blanca", "negro", "mediano", "Z001", "Laura"
      )

    {:ok, state, _pet} =
      PetManager.register_pet(
        state, "PET021", :found, "gato", nil,
        "Pata blanca", "gris", "pequeño", "Z002", "Carlos"
      )

    {:ok, state, _pet} =
      PetManager.register_pet(
        state, "PET022", :lost, "perro", "Max",
        "Orejas largas", "café", "grande", "Z002", "Maria"
      )

    state
  end

  test "lists all registered pets" do
    assert {:ok, pets} = PetManager.list_pets(state_with_pets())

    assert length(pets) == 3
  end

  test "filters pets by species" do
    assert {:ok, pets} =
             PetManager.list_pets(
               state_with_pets(), %{species: "perro"}
             )

    assert length(pets) == 2
    assert Enum.all?(pets, fn pet -> pet.species == "perro" end)
  end

  test "filters pets by zone" do
    assert {:ok, pets} =
             PetManager.list_pets(
               state_with_pets(), %{zone_code: "Z001"}
             )

    assert length(pets) == 1
    assert hd(pets).id == "PET020"
  end

  test "filters pets by status" do
    state = state_with_pets()

    {:ok, state, _pet} =
      PetManager.update_pet_status(state, "PET020", :resolved)

    assert {:ok, pets} =
             PetManager.list_pets(state, %{status: :resolved})

    assert length(pets) == 1
    assert hd(pets).id == "PET020"
  end

  test "combines multiple pet filters" do
    assert {:ok, pets} =
             PetManager.list_pets(
               state_with_pets(),
               %{species: "perro", zone_code: "Z002"}
             )

    assert length(pets) == 1
    assert hd(pets).id == "PET022"
  end

  test "rejects an invalid pet filter" do
    assert {:error, :invalid_filters} =
             PetManager.list_pets(
               state_with_pets(), %{unknown: "value"}
             )
  end

  test "rejects an invalid pet status filter" do
    assert {:error, :invalid_filters} =
             PetManager.list_pets(
               state_with_pets(), %{status: :unknown}
             )
  end

end
