defmodule EmergencySystem.Processes.InventoryConcurrencyTest do
  use ExUnit.Case, async: false

  alias EmergencySystem.Data
  alias EmergencySystem.Assignments.AssignmentManager
  alias EmergencySystem.Processes.StateServer

  test "evita asignar más recursos de los disponibles ante solicitudes simultáneas" do
    initial_state =
      Data.initial_state()
      |> put_in([:needs, "N001"], %{
        id: "N001",
        type: "water",
        description: "Agua para emergencia",
        quantity: 8,
        zone_code: "zona_norte",
        priority: :critical,
        reporter: "usuario1",
        status: :pending
      })
      |> put_in([:resources, "R001"], %{
        code: "R001",
        name: "Agua potable",
        category: :water,
        unit: "litros",
        description: "Agua para consumo"
      })
      |> put_in([:resource_stocks, {"R001", "centro_acopio_1"}], 5)

    state_server = start_supervised!({StateServer, initial_state: initial_state})

    requests =
      for _ <- 1..2 do
        Task.async(fn ->
          StateServer.transact(state_server, fn state ->
            AssignmentManager.assign_resource(
              state,
              "N001",
              "R001",
              "centro_acopio_1",
              4
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
        match?({:error, :insufficient_inventory}, result)
      end)

    final_state = StateServer.get_state(state_server)

    assert length(successes) == 1
    assert length(failures) == 1
    assert final_state.resource_stocks[{"R001", "centro_acopio_1"}] == 1
    assert length(final_state.resource_assignments) == 1
  end
end
