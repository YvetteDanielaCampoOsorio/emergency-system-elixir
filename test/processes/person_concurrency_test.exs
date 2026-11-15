defmodule EmergencySystem.Processes.PersonConcurrencyTest do
  use ExUnit.Case, async: false

  alias EmergencySystem.Data
  alias EmergencySystem.People.PersonManager
  alias EmergencySystem.Processes.StateServer

  test "evita actualizar simultaneamente el estado de una misma persona" do
    initial_state =
      Data.initial_state()
      |> put_in([:people, "P001"], %{
        id: "P001",
        name: "Juan Perez",
        reference: "CC123",
        age: 30,
        zone_code: "zona_norte",
        status: :located
      })

    state_server = start_supervised!({StateServer, initial_state: initial_state})

    requests =
      for _ <- 1..2 do
        Task.async(fn ->
          StateServer.transact(state_server, fn state ->
            PersonManager.update_person_status(
              state,
              "P001",
              :reunified
            )
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
        match?({:error, :invalid_transition}, result)
      end)

    final_state = StateServer.get_state(state_server)

    assert length(successes) == 1
    assert length(failures) == 1
    assert final_state.people["P001"].status == :reunified
    assert length(final_state.person_status_history) == 1
  end
end
