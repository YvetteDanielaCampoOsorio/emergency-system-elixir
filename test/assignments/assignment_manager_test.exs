
defmodule EmergencySystem.Assignments.AssignmentManagerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Assignments.AssignmentManager

  # --------------------------------------------------
  # CONFIGURACIÓN DE PRUEBAS
  # --------------------------------------------------

  setup do
    state =
      Data.initial_state()
      |> Map.put(:needs, %{
        "N001" => %{
          id: "N001",
          type: "water",
          description: "Agua para una comunidad",
          quantity: 100,
          zone_code: "Z001",
          priority: :high,
          reporter: "usuario1",
          status: :pending
        }
      })
      |> Map.put(:resources, %{
        "R001" => %{
          code: "R001",
          name: "Agua potable",
          category: :water,
          unit: "litros",
          description: "Agua para consumo"
        }
      })
      |> Map.put(:resource_stocks, %{
        {"R001", "centro_acopio_1"} => 200
      })

    %{state: state}
  end

  # --------------------------------------------------
  # ASIGNACIÓN EXITOSA
  # --------------------------------------------------

  test "asigna recursos correctamente", %{state: state} do
    assert {:ok, updated_state, assignment} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               30
             )

    assert assignment.need_id == "N001"
    assert assignment.resource_code == "R001"
    assert assignment.quantity == 30

    assert updated_state.resource_stocks[
             {"R001", "centro_acopio_1"}
           ] == 170

    assert updated_state.needs["N001"].status == :assigned
    assert length(updated_state.resource_assignments) == 1
    assert length(updated_state.resource_movements) == 1
  end

  # --------------------------------------------------
  # VALIDACIÓN DE NECESIDADES Y RECURSOS
  # --------------------------------------------------

  test "rechaza una necesidad inexistente", %{state: state} do
    assert {:error, :need_not_found} =
             AssignmentManager.assign_resource(
               state,
               "N999",
               "R001",
               "centro_acopio_1",
               30
             )
  end

  test "rechaza un recurso inexistente", %{state: state} do
    assert {:error, :resource_not_found} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R999",
               "centro_acopio_1",
               30
             )
  end

  test "rechaza una ubicación sin inventario registrado", %{state: state} do
    assert {:error, :stock_not_found} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_2",
               30
             )
  end

  test "rechaza recursos de una categoría diferente", %{state: state} do
    resource = %{state.resources["R001"] | category: :food}

    updated_state =
      put_in(state.resources["R001"], resource)

    assert {:error, :resource_type_mismatch} =
             AssignmentManager.assign_resource(
               updated_state,
               "N001",
               "R001",
               "centro_acopio_1",
               30
             )
  end

  # --------------------------------------------------
  # VALIDACIÓN DE CANTIDADES
  # --------------------------------------------------

  test "rechaza cantidades mayores al inventario disponible", %{
    state: state
  } do
    assert {:error, :insufficient_inventory} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               250
             )
  end

  test "rechaza cantidades que superan lo solicitado", %{
    state: state
  } do
    assert {:error, :exceeds_need_quantity} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               110
             )
  end

  test "no permite superar la cantidad solicitada con varias asignaciones",
       %{state: state} do
    assert {:ok, updated_state, _assignment} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               70
             )

    assert {:error, :exceeds_need_quantity} =
             AssignmentManager.assign_resource(
               updated_state,
               "N001",
               "R001",
               "centro_acopio_1",
               31
             )
  end

  test "rechaza cantidades iguales o menores a cero", %{state: state} do
    assert {:error, :invalid_quantity} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               0
             )

    assert {:error, :invalid_quantity} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "centro_acopio_1",
               -10
             )
  end

  # --------------------------------------------------
  # VALIDACIÓN DEL ESTADO DE LA NECESIDAD
  # --------------------------------------------------

  test "rechaza necesidades que ya fueron atendidas", %{state: state} do
    updated_state =
      put_in(state.needs["N001"].status, :attended)

    assert {:error, :invalid_need_status} =
             AssignmentManager.assign_resource(
               updated_state,
               "N001",
               "R001",
               "centro_acopio_1",
               30
             )
  end

  test "rechaza necesidades canceladas", %{state: state} do
    updated_state =
      put_in(state.needs["N001"].status, :cancelled)

    assert {:error, :invalid_need_status} =
             AssignmentManager.assign_resource(
               updated_state,
               "N001",
               "R001",
               "centro_acopio_1",
               30
             )
  end

  # --------------------------------------------------
  # VALIDACIÓN DE ARGUMENTOS Y ESTADO
  # --------------------------------------------------

  test "rechaza identificadores y ubicaciones vacías", %{state: state} do
    assert {:error, :empty_fields} =
             AssignmentManager.assign_resource(
               state,
               "",
               "R001",
               "centro_acopio_1",
               30
             )

    assert {:error, :empty_fields} =
             AssignmentManager.assign_resource(
               state,
               "N001",
               "R001",
               "",
               30
             )
  end

  test "rechaza un estado inválido" do
    assert {:error, :invalid_state} =
             AssignmentManager.assign_resource(
               %{},
               "N001",
               "R001",
               "centro_acopio_1",
               30
             )
  end
end
