defmodule EmergencySystem.Processes.PetConcurrencyTest do
  use ExUnit.Case, async: false

  alias EmergencySystem.Data
  alias EmergencySystem.Pets.PetManager
  alias EmergencySystem.Processes.StateServer

  test "evita confirmar dos veces la misma coincidencia de mascotas" do
    initial_state =
      Data.initial_state()
      |> put_in([:pets, "L001"], %{
        id: "L001",
        report_type: :lost,
        species: "perro",
        name: "Luna",
        characteristics: "Mancha blanca en el pecho",
        color: "negro",
        size: "mediano",
        zone_code: "zona_norte",
        contact: "contacto1",
        status: :active,
        timestamp: DateTime.utc_now()
      })
      |> put_in([:pets, "F001"], %{
        id: "F001",
        report_type: :found,
        species: "perro",
        name: "Luna",
        characteristics: "Mancha blanca en el pecho",
        color: "negro",
        size: "mediano",
        zone_code: "zona_norte",
        contact: "contacto2",
        status: :active,
        timestamp: DateTime.utc_now()
      })

    state_server = start_supervised!({StateServer, initial_state: initial_state})

    requests =
      for _ <- 1..2 do
        Task.async(fn ->
          StateServer.transact(state_server, fn state ->
            case PetManager.confirm_match(state, "L001", "F001") do
              {:ok, updated_state, lost_pet, found_pet} ->
                {:ok, updated_state, {lost_pet, found_pet}}

              {:error, reason} ->
                {:error, reason}
            end
          end)
        end)
      end

    results = Task.await_many(requests)

    successes =
      Enum.filter(results, fn result ->
        match?({:ok, _}, result)
      end)

    failures =
      Enum.filter(results, fn result ->
        match?({:error, :resolved_report}, result)
      end)

    final_state = StateServer.get_state(state_server)

    assert length(successes) == 1
    assert length(failures) == 1
    assert final_state.pets["L001"].status == :resolved
    assert final_state.pets["F001"].status == :resolved
  end
end
