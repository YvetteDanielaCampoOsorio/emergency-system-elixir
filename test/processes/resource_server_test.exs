
defmodule EmergencySystem.Processes.ResourceServerTest do
  use ExUnit.Case, async: false

  alias EmergencySystem.Data
  alias EmergencySystem.Processes.StateServer
  alias EmergencySystem.Processes.ResourceServer

  setup do
    state_server =
      start_supervised!(
        {StateServer, initial_state: Data.initial_state()}
      )

    resource_server =
      start_supervised!(
        {ResourceServer, state_server: state_server}
      )

    %{resource_server: resource_server}
  end

  # ============================================================
  # REGISTRO Y CONSULTA DE RECURSOS
  # ============================================================

  test "registra un recurso correctamente", %{resource_server: server} do
    assert {:ok, resource} =
             ResourceServer.register_resource(
               server,
               "R001",
               "Agua potable",
               :water,
               100,
               "litros",
               "centro_1",
               "Agua para consumo"
             )

    assert resource.code == "R001"
    assert resource.name == "Agua potable"
  end

  test "consulta los recursos registrados", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, resources} = ResourceServer.list_resources(server)

    assert length(resources) == 1
    assert hd(resources).code == "R001"
  end

  test "filtra los recursos por categoría", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, resources} =
             ResourceServer.filter_by_category(server, :water)

    assert length(resources) == 1
  end

  test "filtra los recursos por ubicación", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, resources} =
             ResourceServer.filter_by_location(server, "centro_1")

    assert length(resources) == 1
  end

  # ============================================================
  # MOVIMIENTOS DE INVENTARIO
  # ============================================================

  test "registra una entrada de inventario", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, _movement} =
             ResourceServer.register_entry(server, "R001", "centro_1", 50)

    assert {:ok, movements} =
             ResourceServer.list_resource_movements(server)

    assert length(movements) == 1
  end

  test "registra una salida de inventario", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, _movement} =
             ResourceServer.register_exit(server, "R001", "centro_1", 20)

    assert {:ok, movements} =
             ResourceServer.list_resource_movements(server)

    assert length(movements) == 1
  end

  test "transfiere recursos entre ubicaciones", %{resource_server: server} do
    assert {:ok, _resource} =
             ResourceServer.register_resource(
               server, "R001", "Agua potable", :water,
               100, "litros", "centro_1", "Agua para consumo"
             )

    assert {:ok, _movement} =
             ResourceServer.transfer_resource(
               server, "R001", "centro_1", "centro_2", 30
             )

    assert {:ok, resources} =
             ResourceServer.filter_by_location(server, "centro_2")

    assert Enum.any?(resources, &(&1.code == "R001"))
  end

  # ============================================================
  # COMUNICACIÓN ENTRE PROCESOS
  # ============================================================

  test "procesa registros concurrentes de recursos", %{resource_server: server} do
    tasks =
      for number <- 1..10 do
        Task.async(fn ->
          ResourceServer.register_resource(
            server,
            "R#{number}",
            "Recurso #{number}",
            :water,
            100,
            "litros",
            "centro_1",
            "Recurso de prueba"
          )
        end)
      end

    results = Task.await_many(tasks)

    assert Enum.all?(results, &match?({:ok, _}, &1))

    assert {:ok, resources} = ResourceServer.list_resources(server)

    assert length(resources) == 10
  end
end
