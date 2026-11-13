defmodule EmergencySystem.Needs.NeedManagerTest do
  use ExUnit.Case

  alias EmergencySystem.Data
  alias EmergencySystem.Needs.NeedManager

  setup do
    state = Data.initial_state()

    {:ok, state, _zone} =
      EmergencySystem.Zones.ZoneManager.create_zone(
        state,
        "Z001",
        "Centro",
        :high,
        250
      )

    {:ok, state, _user} =
      EmergencySystem.Users.UserManager.connect(
        state,
        "usuario1",
        "password123",
        %{
          full_name: "Usuario de prueba",
          role: :citizen,
          zone: "Z001"
        }
      )

    %{state: state}
  end

  test "registra una necesidad correctamente", %{state: state} do
    result =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, updated_state, need} = result

    assert need.id == "N001"
    assert need.status == :pending
    assert Map.has_key?(updated_state.needs, "N001")
  end

  test "rechaza cantidades negativas", %{state: state} do
    assert {:error, :invalid_quantity} =
             NeedManager.register_need(
               state,
               "N002",
               "food",
               "Alimentos",
               -5,
               "Z001",
               :high,
               "usuario1"
             )
  end

  test "rechaza prioridades no válidas", %{state: state} do
    assert {:error, :invalid_priority} =
             NeedManager.register_need(
               state,
               "N003",
               "water",
               "Agua",
               20,
               "Z001",
               :urgent,
               "usuario1"
             )
  end

  test "rechaza identificadores duplicados", %{state: state} do
    assert {:ok, updated_state, _need} =
             NeedManager.register_need(
               state,
               "N004",
               "food",
               "Alimentos",
               50,
               "Z001",
               :critical,
               "usuario1"
             )

    assert {:error, :need_already_exists} =
             NeedManager.register_need(
               updated_state,
               "N004",
               "water",
               "Agua",
               20,
               "Z001",
               :high,
               "usuario1"
             )
  end

  test "lista todas las necesidades registradas", %{state: state} do
    {:ok, updated_state, _need} =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, needs} = NeedManager.list_needs(updated_state)
    assert length(needs) == 1
    assert hd(needs).id == "N001"
  end

  test "filtra las necesidades por zona", %{state: state} do
    {:ok, updated_state, _need} =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, needs} = NeedManager.filter_by_zone(updated_state, "Z001")
    assert length(needs) == 1
    assert hd(needs).id == "N001"
  end

  test "filtra las necesidades por tipo", %{state: state} do
    {:ok, updated_state, _need} =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, needs} = NeedManager.filter_by_type(updated_state, "food")
    assert length(needs) == 1
    assert hd(needs).id == "N001"
    assert hd(needs).type == "food"
  end

  test "filtra las necesidades por prioridad", %{state: state} do
    {:ok, updated_state, _need} =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, needs} =
             NeedManager.filter_by_priority(updated_state, :critical)

    assert length(needs) == 1
    assert hd(needs).id == "N001"
    assert hd(needs).priority == :critical
  end

  test "filtra las necesidades por estado", %{state: state} do
    {:ok, updated_state, _need} =
      NeedManager.register_need(
        state,
        "N001",
        "food",
        "Se necesitan alimentos",
        50,
        "Z001",
        :critical,
        "usuario1"
      )

    assert {:ok, needs} =
             NeedManager.filter_by_status(updated_state, :pending)

    assert length(needs) == 1
    assert hd(needs).id == "N001"
    assert hd(needs).status == :pending
  end

  test "rechaza filtrar por una zona vacía", %{state: state} do
    assert {:error, :empty_fields} =
             NeedManager.filter_by_zone(state, "   ")
  end

  test "rechaza filtrar por un tipo vacío", %{state: state} do
    assert {:error, :empty_fields} =
             NeedManager.filter_by_type(state, "   ")
  end

  test "rechaza filtrar por una prioridad inválida", %{state: state} do
    assert {:error, :invalid_priority} =
             NeedManager.filter_by_priority(state, :urgent)
  end

  test "rechaza filtrar por un estado inválido", %{state: state} do
    assert {:error, :invalid_status} =
             NeedManager.filter_by_status(state, :unknown)
  end

  test "rechaza argumentos incorrectos al registrar una necesidad", %{state: state} do
    assert {:error, :invalid_arguments} =
             NeedManager.register_need(
               state,
               123,
               "food",
               "Alimentos",
               50,
               "Z001",
               :critical,
               "usuario1"
             )
  end

  test "rechaza una zona con tipo de dato incorrecto", %{state: state} do
    assert {:error, :invalid_arguments} =
             NeedManager.filter_by_zone(state, 123)
  end

  test "rechaza un tipo con tipo de dato incorrecto", %{state: state} do
    assert {:error, :invalid_arguments} =
             NeedManager.filter_by_type(state, 123)
  end

  test "rechaza prioridades y estados con tipo de dato incorrecto", %{state: state} do
    assert {:error, :invalid_arguments} =
             NeedManager.filter_by_priority(state, "critical")

    assert {:error, :invalid_arguments} =
             NeedManager.filter_by_status(state, "pending")
  end

  test "rechaza consultar un estado sin mapa de necesidades" do
    assert {:error, :invalid_state} =
             NeedManager.list_needs(%{})
  end

  test "rechaza filtrar cuando el estado del sistema es inválido" do
    invalid_state = %{}

    assert {:error, :invalid_state} =
             NeedManager.filter_by_zone(invalid_state, "Z001")

    assert {:error, :invalid_state} =
             NeedManager.filter_by_type(invalid_state, "food")

    assert {:error, :invalid_state} =
             NeedManager.filter_by_priority(invalid_state, :critical)

    assert {:error, :invalid_state} =
             NeedManager.filter_by_status(invalid_state, :pending)
  end

  describe "update_need_status/3" do
    setup %{state: state} do
      {:ok, state, _need} =
        EmergencySystem.Needs.NeedManager.register_need(
          state,
          "N001",
          "water",
          "Agua potable",
          100,
          "Z001",
          :high,
          "usuario1"
        )

      %{state: state}
    end

    test "actualiza una necesidad de pendiente a asignada", %{state: state} do
      assert {:ok, updated_state, need} =
               EmergencySystem.Needs.NeedManager.update_need_status(
                 state,
                 "N001",
                 :assigned
               )

      assert need.status == :assigned
      assert updated_state.needs["N001"].status == :assigned
    end

    test "rechaza una transición no permitida", %{state: state} do
      assert {:error, :invalid_transition} =
               EmergencySystem.Needs.NeedManager.update_need_status(
                 state,
                 "N001",
                 :attended
               )
    end

    test "rechaza cambiar el estado de una necesidad atendida", %{state: state} do
      {:ok, state, _need} =
        EmergencySystem.Needs.NeedManager.update_need_status(
          state,
          "N001",
          :assigned
        )

      {:ok, state, _need} =
        EmergencySystem.Needs.NeedManager.update_need_status(
          state,
          "N001",
          :in_progress
        )

      {:ok, state, _need} =
        EmergencySystem.Needs.NeedManager.update_need_status(
          state,
          "N001",
          :attended
        )

      assert {:error, :invalid_transition} =
               EmergencySystem.Needs.NeedManager.update_need_status(
                 state,
                 "N001",
                 :pending
               )
    end

    test "rechaza actualizar una necesidad inexistente", %{state: state} do
      assert {:error, :need_not_found} =
               EmergencySystem.Needs.NeedManager.update_need_status(
                 state,
                 "N999",
                 :assigned
               )
    end

    test "rechaza un estado que no está permitido", %{state: state} do
      assert {:error, :invalid_status} =
               EmergencySystem.Needs.NeedManager.update_need_status(
                 state,
                 "N001",
                 :unknown
               )
    end
  end

  describe "sort_by_priority/1" do
    test "ordena las necesidades de mayor a menor prioridad", %{state: state} do
      needs = [
        %{
          id: "N001",
          type: "water",
          priority: :low,
          status: :pending
        },
        %{
          id: "N002",
          type: "food",
          priority: :critical,
          status: :pending
        },
        %{
          id: "N003",
          type: "medicine",
          priority: :medium,
          status: :pending
        },
        %{
          id: "N004",
          type: "shelter",
          priority: :high,
          status: :pending
        }
      ]

      state = Map.put(state, :needs, Map.new(needs, fn need -> {need.id, need} end))

      assert {:ok, sorted_needs} =
               EmergencySystem.Needs.NeedManager.sort_by_priority(state)

      assert Enum.map(sorted_needs, & &1.priority) ==
               [:critical, :high, :medium, :low]
    end
  end
end
