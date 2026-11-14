
defmodule EmergencySystem.Processes.StateServerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Processes.StateServer

  # ============================================================
  # PRUEBAS DE INICIO DEL SERVIDOR
  # ============================================================

  test "inicia el servidor con el estado inicial" do
    assert {:ok, pid} = StateServer.start_link()

    assert is_pid(pid)
    assert Data.initial_state() == StateServer.get_state(pid)

    GenServer.stop(pid)
  end

  test "inicia el servidor con un estado personalizado" do
    custom_state =
      Data.initial_state()
      |> Map.put(:activity_log, [:test_activity])

    assert {:ok, pid} =
             StateServer.start_link(initial_state: custom_state)

    assert custom_state == StateServer.get_state(pid)

    GenServer.stop(pid)
  end

  test "rechaza un estado inicial inválido" do
    assert {:error, :invalid_initial_state} =
            GenServer.start(StateServer, %{})
  end

  # ============================================================
  # PRUEBAS DE CONSULTA
  # ============================================================

  test "obtiene el estado actual del servidor" do
    assert {:ok, pid} = StateServer.start_link()

    state = StateServer.get_state(pid)

    assert is_map(state)
    assert Map.has_key?(state, :users)

    GenServer.stop(pid)
  end

  # ============================================================
  # PRUEBAS DE MODIFICACIÓN
  # ============================================================

  test "actualiza correctamente el estado compartido" do
    assert {:ok, pid} = StateServer.start_link()

    operation = fn state ->
      updated_state =
        Map.put(state, :activity_log, [:new_activity])

      {:ok, updated_state, :activity_registered}
    end

    assert {:ok, :activity_registered} =
             StateServer.transact(pid, operation)

    assert StateServer.get_state(pid).activity_log == [:new_activity]

    GenServer.stop(pid)
  end

  test "no modifica el estado cuando la operación retorna un error" do
    assert {:ok, pid} = StateServer.start_link()

    original_state = StateServer.get_state(pid)

    operation = fn _state ->
      {:error, :operation_rejected}
    end

    assert {:error, :operation_rejected} =
             StateServer.transact(pid, operation)

    assert StateServer.get_state(pid) == original_state

    GenServer.stop(pid)
  end

  test "rechaza operaciones que no son funciones" do
    assert {:ok, pid} = StateServer.start_link()

    assert {:error, :invalid_operation} =
             StateServer.transact(pid, :invalid)

    GenServer.stop(pid)
  end

  test "rechaza resultados inválidos de una operación" do
    assert {:ok, pid} = StateServer.start_link()

    operation = fn _state ->
      :invalid_result
    end

    assert {:error, :invalid_operation_result} =
             StateServer.transact(pid, operation)

    GenServer.stop(pid)
  end

  test "no modifica el estado si la operación produce un error" do
    assert {:ok, pid} = StateServer.start_link()

    original_state = StateServer.get_state(pid)

    operation = fn _state ->
      raise "Error de prueba"
    end

    assert {:error, :operation_failed} =
             StateServer.transact(pid, operation)

    assert StateServer.get_state(pid) == original_state

    GenServer.stop(pid)
  end

  test "rechaza estados modificados que no cumplen la estructura requerida" do
    assert {:ok, pid} = StateServer.start_link()

    operation = fn _state ->
      {:ok, %{users: %{}}, :invalid_update}
    end

    assert {:error, :invalid_state} =
             StateServer.transact(pid, operation)

    assert Data.initial_state() == StateServer.get_state(pid)

    GenServer.stop(pid)
  end
end
