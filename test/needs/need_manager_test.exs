
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
        state, "N002", "food", "Alimentos", -5,
        "Z001", :high, "usuario1"
      )
  end

  test "rechaza prioridades no válidas", %{state: state} do
    assert {:error, :invalid_priority} =
      NeedManager.register_need(
        state, "N003", "water", "Agua", 20,
        "Z001", :urgent, "usuario1"
      )
  end

  test "rechaza identificadores duplicados", %{state: state} do
    assert {:ok, updated_state, _need} =
      NeedManager.register_need(
        state, "N004", "food", "Alimentos", 50,
        "Z001", :critical, "usuario1"
      )

    assert {:error, :need_already_exists} =
      NeedManager.register_need(
        updated_state, "N004", "water", "Agua", 20,
        "Z001", :high, "usuario1"
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


end
