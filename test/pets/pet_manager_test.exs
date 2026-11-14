
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

  # ============================================================
  # PRUEBAS DEL ALGORITMO DE COINCIDENCIA
  # ============================================================

  describe "calculate_similarity/2" do
    setup do
      lost_pet = %{
        id: "PET001",
        report_type: :lost,
        species: "perro",
        name: "Luna",
        characteristics: "mancha blanca",
        color: "negro",
        size: "mediano",
        zone_code: "Z001",
        contact: "Laura",
        status: :active
      }

      found_pet = %{
        id: "PET002",
        report_type: :found,
        species: "perro",
        name: "Luna",
        characteristics: "mancha blanca",
        color: "negro",
        size: "mediano",
        zone_code: "Z001",
        contact: "Carlos",
        status: :active
      }

      %{lost_pet: lost_pet, found_pet: found_pet}
    end

    test "returns 100 when all attributes match", context do
      assert {:ok, 100} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 context.found_pet
               )
    end

    test "ignores uppercase and surrounding spaces", context do
      found_pet = %{
        context.found_pet
        | color: " NEGRO ",
          characteristics: "MANCHA BLANCA"
      }

      assert {:ok, 100} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 found_pet
               )
    end

    test "returns 75 when color does not match", context do
      found_pet = %{context.found_pet | color: "blanco"}

      assert {:ok, 75} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 found_pet
               )
    end

    test "returns 0 when no comparable attributes match", context do
      found_pet = %{
        context.found_pet
        | name: "Max",
          characteristics: "orejas largas",
          color: "blanco",
          size: "grande"
      }

      assert {:ok, 0} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 found_pet
               )
    end

    test "ignores name when it is unknown", context do
      lost_pet = %{context.lost_pet | name: nil}
      found_pet = %{context.found_pet | name: nil}

      assert {:ok, 100} =
               PetManager.calculate_similarity(lost_pet, found_pet)
    end

    test "returns error when species are different", context do
      found_pet = %{context.found_pet | species: "gato"}

      assert {:error, :different_species} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 found_pet
               )
    end

    test "rejects reports with invalid types", context do
      invalid_pet = %{context.lost_pet | report_type: :found}

      assert {:error, :invalid_report_type} =
               PetManager.calculate_similarity(
                 invalid_pet,
                 context.found_pet
               )
    end

    test "rejects resolved reports", context do
      resolved_pet = %{context.found_pet | status: :resolved}

      assert {:error, :resolved_report} =
               PetManager.calculate_similarity(
                 context.lost_pet,
                 resolved_pet
               )
    end

    test "rejects invalid report data" do
      assert {:error, :invalid_report} =
               PetManager.calculate_similarity(%{}, %{})
    end
  end

  # ============================================================
  # PRUEBAS DE BÚSQUEDA DE COINCIDENCIAS
  # ============================================================

  describe "find_possible_matches/2" do
    test "finds matching lost and found pets" do
      state = state_with_pets()

      assert {:ok, matches} = PetManager.find_possible_matches(state)

      assert Enum.any?(matches, fn match ->
        match.lost_pet_id == "PET020" and
          match.found_pet_id == "PET021"
      end) == false
    end

    test "returns matches ordered by similarity score" do
      state = state_with_pets()

      assert {:ok, matches} = PetManager.find_possible_matches(state)

      scores = Enum.map(matches, & &1.score)

      assert scores == Enum.sort(scores, :desc)
    end

    test "uses the minimum similarity score" do
      state = state_with_pets()

      assert {:ok, matches} = PetManager.find_possible_matches(state, 100)

      assert Enum.all?(matches, fn match -> match.score >= 100 end)
    end

    test "does not compare pets of the same report type" do
      state = state_with_pets()

      assert {:ok, matches} = PetManager.find_possible_matches(state)

      assert Enum.all?(matches, fn match ->
        lost_pet = state.pets[match.lost_pet_id]
        found_pet = state.pets[match.found_pet_id]

        lost_pet.report_type == :lost and
          found_pet.report_type == :found
      end)
    end

    test "does not include resolved reports" do
      state = state_with_pets()

      {:ok, state, _pet} =
        PetManager.update_pet_status(state, "PET020", :resolved)

      assert {:ok, matches} = PetManager.find_possible_matches(state)

      refute Enum.any?(matches, fn match ->
        match.lost_pet_id == "PET020"
      end)
    end

    test "returns an empty list when there are no possible matches" do
      state = %{
        initial_state()
        | pets: %{}
      }

      assert {:ok, []} = PetManager.find_possible_matches(state)
    end

    test "rejects an invalid minimum score" do
      state = state_with_pets()

      assert {:error, :invalid_score} =
               PetManager.find_possible_matches(state, 150)
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               PetManager.find_possible_matches(%{})
    end
  end

  describe "confirm_match/3" do
    test "confirms a match and resolves both pet reports" do
      state = state_with_pets()

      {:ok, state, _found_pet} =
        PetManager.register_pet(
          state,
          "PET023",
          :found,
          "perro",
          "Luna",
          "Mancha blanca",
          "negro",
          "mediano",
          "Z001",
          "Carlos"
        )

      assert {:ok, updated_state, lost_pet, found_pet} =
               PetManager.confirm_match(state, "PET020", "PET023")

      assert lost_pet.status == :resolved
      assert found_pet.status == :resolved

      assert updated_state.pets["PET020"].status == :resolved
      assert updated_state.pets["PET023"].status == :resolved
    end

    test "rejects a report that does not exist" do
      state = state_with_pets()

      assert {:error, :pet_not_found} =
               PetManager.confirm_match(state, "PET999", "PET021")
    end

    test "rejects two reports with the same identifier" do
      state = state_with_pets()

      assert {:error, :same_report} =
               PetManager.confirm_match(state, "PET020", "PET020")
    end

    test "rejects an invalid lost report type" do
      state = state_with_pets()

      assert {:error, :invalid_lost_report} =
               PetManager.confirm_match(state, "PET021", "PET020")
    end

    test "rejects an invalid found report type" do
      state = state_with_pets()

      assert {:error, :invalid_found_report} =
               PetManager.confirm_match(state, "PET020", "PET022")
    end

    test "rejects reports that have already been resolved" do
      state = state_with_pets()

      {:ok, state, _pet} =
        PetManager.update_pet_status(state, "PET020", :resolved)

      assert {:error, :resolved_report} =
               PetManager.confirm_match(state, "PET020", "PET021")
    end

    test "rejects invalid identifiers" do
      state = state_with_pets()

      assert {:error, :invalid_id} =
               PetManager.confirm_match(state, "", "PET021")
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               PetManager.confirm_match(%{}, "PET020", "PET021")
    end
  end

end
