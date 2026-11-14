defmodule EmergencySystem.Processes.NeedServerTest do
  use ExUnit.Case, async: false

  alias EmergencySystem.Data
  alias EmergencySystem.Processes.StateServer
  alias EmergencySystem.Processes.NeedServer

  setup do
    initial_state =
      Data.initial_state()
      |> put_in([:zones, "Z001"], %{code: "Z001", name: "Zona Norte"})
      |> put_in([:users, "reporter"], %{username: "reporter"})

    state_server =
      start_supervised!(
        {StateServer, initial_state: initial_state}
      )

    need_server =
      start_supervised!(
        {NeedServer, state_server: state_server}
      )

    %{need_server: need_server}
  end

  # ============================================================
  # REGISTRO DE NECESIDADES
  # ============================================================

  test "registra una necesidad correctamente", %{need_server: server} do
    assert {:ok, need} =
             NeedServer.register_need(
               server,
               "N001",
               "water",
               "Se necesita agua potable",
               50,
               "Z001",
               :high,
               "reporter"
             )

    assert need.id == "N001"
    assert need.status == :pending
  end

  test "rechaza el registro de una necesidad duplicada", %{need_server: server} do
    args = [
      "N001",
      "water",
      "Se necesita agua",
      50,
      "Z001",
      :high,
      "reporter"
    ]

    assert {:ok, _need} = apply(NeedServer, :register_need, [server | args])
    assert {:error, :need_already_exists} =
         apply(NeedServer, :register_need, [server | args])
  end

  # ============================================================
  # CONSULTA DE NECESIDADES
  # ============================================================

  test "consulta las necesidades registradas", %{need_server: server} do
    assert {:ok, _need} =
             NeedServer.register_need(
               server, "N001", "water", "Agua potable",
               50, "Z001", :high, "reporter"
             )

    assert {:ok, needs} = NeedServer.list_needs(server)

    assert length(needs) == 1
    assert hd(needs).id == "N001"
  end

  test "filtra las necesidades por zona", %{need_server: server} do
    assert {:ok, _need} =
             NeedServer.register_need(
               server, "N001", "water", "Agua potable",
               50, "Z001", :high, "reporter"
             )

    assert {:ok, needs} =
             NeedServer.list_needs(server, %{zone_code: "Z001"})

    assert length(needs) == 1
  end

  # ============================================================
  # ACTUALIZACIÓN DE ESTADOS
  # ============================================================

  test "actualiza el estado de una necesidad", %{need_server: server} do
    assert {:ok, _need} =
             NeedServer.register_need(
               server, "N001", "water", "Agua potable",
               50, "Z001", :high, "reporter"
             )

    assert {:ok, updated_need} =
             NeedServer.update_need_status(server, "N001", :assigned)

    assert updated_need.status == :assigned
  end

  # ============================================================
  # COMUNICACIÓN ENTRE PROCESOS
  # ============================================================

  test "procesa solicitudes concurrentes", %{need_server: server} do
    tasks =
      for number <- 1..10 do
        Task.async(fn ->
          NeedServer.register_need(
            server,
            "N#{number}",
            "water",
            "Solicitud de agua #{number}",
            10,
            "Z001",
            :medium,
            "reporter"
          )
        end)
      end

    results = Task.await_many(tasks)

    assert Enum.all?(results, &match?({:ok, _}, &1))

    assert {:ok, needs} = NeedServer.list_needs(server)

    assert length(needs) == 10
  end
end
