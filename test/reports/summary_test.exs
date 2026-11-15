defmodule EmergencySystem.Reports.SummaryTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Reports.Summary

  describe "pending_needs/1" do
    test "consulta únicamente las necesidades pendientes" do
      state =
        Data.initial_state()
        |> put_in([:needs, "N001"], %{
          id: "N001",
          type: "water",
          quantity: 20,
          status: :pending
        })
        |> put_in([:needs, "N002"], %{
          id: "N002",
          type: "food",
          quantity: 10,
          status: :assigned
        })

      assert {:ok, needs} = Summary.pending_needs(state)

      assert length(needs) == 1
      assert hd(needs).id == "N001"
    end

    test "devuelve una lista vacía cuando no hay necesidades pendientes" do
      state = Data.initial_state()

      assert {:ok, []} = Summary.pending_needs(state)
    end

    test "rechaza un estado inválido" do
      assert {:error, :invalid_arguments} =
               Summary.pending_needs(nil)
    end
  end

  describe "critical_resources/1" do
    test "identifica recursos sin existencias" do
      state =
        Data.initial_state()
        |> put_in([:resources, "R001"], %{
          code: "R001",
          name: "Agua potable",
          category: :water,
          unit: "litros"
        })
        |> put_in([:resources, "R002"], %{
          code: "R002",
          name: "Alimentos",
          category: :food,
          unit: "unidades"
        })
        |> put_in([:resource_stocks, {"R001", "centro_1"}], 0)
        |> put_in([:resource_stocks, {"R002", "centro_1"}], 50)

      assert {:ok, resources} = Summary.critical_resources(state)

      assert length(resources) == 1
      assert hd(resources).code == "R001"
      assert hd(resources).quantity == 0
    end

    test "devuelve una lista vacía cuando no hay recursos agotados" do
      state =
        Data.initial_state()
        |> put_in([:resources, "R001"], %{
          code: "R001",
          name: "Agua potable",
          category: :water,
          unit: "litros"
        })
        |> put_in([:resource_stocks, {"R001", "centro_1"}], 20)

      assert {:ok, []} = Summary.critical_resources(state)
    end

    test "rechaza una estructura de inventario inválida" do
      assert {:error, :invalid_state} =
               Summary.critical_resources(%{resources: %{}})
    end

    test "rechaza un estado que no es un mapa" do
      assert {:error, :invalid_state} =
               Summary.critical_resources(nil)
    end
  end

describe "summary/1" do
  test "genera un resumen completo del estado del sistema" do
    state =
      Data.initial_state()
      |> Map.merge(%{
        resources: %{
          "R001" => %{
            code: "R001",
            name: "Agua",
            category: :water,
            unit: "litros",
            description: "Agua potable"
          }
        },
        resource_stocks: %{
          {"R001", "central"} => 15,
          {"R001", "north"} => 0
        },
        needs: %{
          "N001" => %{
            id: "N001",
            type: :water,
            description: "Agua para una familia",
            quantity: 10,
            zone_code: "Z001",
            priority: :high,
            reporter: "U001",
            status: :pending
          }
        },
        people: %{
          "P001" => %{
            id: "P001",
            name: "Ana",
            reference: "Familiar",
            age: 25,
            zone_code: "Z001",
            status: :located
          }
        },
        messages: [
          %{
            id: "M001",
            sender: "U001",
            recipient: "U002",
            content: "Necesitamos ayuda",
            timestamp: DateTime.utc_now(),
            status: :pending
          }
        ],
        pets: %{
          "PET001" => %{
            id: "PET001",
            report_type: :lost,
            species: "Perro",
            name: "Max",
            characteristics: "Tiene una mancha blanca",
            color: "Café",
            size: "Mediano",
            zone_code: "Z001",
            contact: "U001",
            status: :active,
            timestamp: DateTime.utc_now()
          }
        },
        shelters: %{
          "A001" => %{
            code: "A001",
            name: "Albergue central",
            zone_code: "Z001",
            capacity: 20,
            occupancy: 5,
            occupants: MapSet.new()
          }
        }
      })

    assert {:ok, report} = Summary.summary(state)

    assert report.total_resources_remaining == 15
    assert report.critical_resources_count == 1
    assert report.pending_needs_count == 1
    assert report.people_count == 1
    assert length(report.located_people) == 1
    assert report.messages_count == 1
    assert report.pending_messages == 1
    assert report.active_pet_reports == 1
    assert report.shelter_occupancy == 5
    assert report.shelter_capacity == 20
  end

  test "genera un resumen vacío cuando no hay registros" do
    assert {:ok, report} = Summary.summary(Data.initial_state())

    assert report.zones_count == 0
    assert report.needs_count == 0
    assert report.resources_count == 0
    assert report.people_count == 0
    assert report.messages_count == 0
    assert report.pets_count == 0
    assert report.shelters_count == 0
    assert report.total_resources_remaining == 0
  end

  test "rechaza un estado inválido" do
    assert {:error, :invalid_arguments} = Summary.summary(nil)
  end
end

end
