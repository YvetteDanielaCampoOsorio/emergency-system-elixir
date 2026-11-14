defmodule EmergencySystem.Resources.ResourceManagerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Resources.ResourceManager

  setup do
    state = Data.initial_state()
    %{state: state}
  end

  describe "register_resource/8" do
    test "registra correctamente un recurso", %{state: state} do
      assert {:ok, updated_state, resource} =
               ResourceManager.register_resource(
                 state,
                 "R001",
                 "Agua potable",
                 :water,
                 200,
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )

      assert resource.code == "R001"

      assert resource.name == "Agua potable"
      assert resource.category == :water
      assert updated_state.resources["R001"] == resource
      assert updated_state.resource_stocks[{"R001", "Z001"}] == 200
    end

    test "rechaza cantidades negativas", %{state: state} do
      assert {:error, :invalid_quantity} =
               ResourceManager.register_resource(
                 state,
                 "R001",
                 "Agua potable",
                 :water,
                 -10,
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )
    end

    test "rechaza categorías no permitidas", %{state: state} do
      assert {:error, :invalid_category} =
               ResourceManager.register_resource(
                 state,
                 "R001",
                 "Agua potable",
                 :invalid,
                 200,
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )
    end

    test "rechaza códigos duplicados", %{state: state} do
      {:ok, state, _resource} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo humano"
        )

      assert {:error, :resource_already_exists} =
               ResourceManager.register_resource(
                 state,
                 "R001",
                 "Alimentos",
                 :food,
                 50,
                 "paquetes",
                 "Z001",
                 "Alimentos no perecederos"
               )
    end

    test "rechaza campos de texto vacíos", %{state: state} do
      assert {:error, :empty_fields} =
               ResourceManager.register_resource(
                 state,
                 " ",
                 "Agua potable",
                 :water,
                 200,
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )
    end

    test "rechaza argumentos con tipos incorrectos", %{state: state} do
      assert {:error, :invalid_arguments} =
               ResourceManager.register_resource(
                 state,
                 "R001",
                 "Agua potable",
                 :water,
                 "200",
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )
    end

    test "rechaza un estado inválido", _context do
      assert {:error, :invalid_state} =
               ResourceManager.register_resource(
                 %{},
                 "R001",
                 "Agua potable",
                 :water,
                 200,
                 "litros",
                 "Z001",
                 "Agua para consumo humano"
               )
    end
  end

  describe "list_resources/1" do
    test "returns all registered resources", %{state: state} do
      {:ok, updated_state, _resource} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      assert {:ok, resources} = ResourceManager.list_resources(updated_state)
      assert length(resources) == 1
      assert hd(resources).code == "R001"
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} = ResourceManager.list_resources(%{})
    end
  end

  describe "filter_by_category/2" do
    test "returns resources matching the category", %{state: state} do
      {:ok, state, _water} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      {:ok, state, _food} =
        ResourceManager.register_resource(
          state,
          "R002",
          "Alimentos",
          :food,
          100,
          "unidades",
          "Z001",
          "Alimentos básicos"
        )

      assert {:ok, resources} =
               ResourceManager.filter_by_category(state, :water)

      assert length(resources) == 1
      assert hd(resources).code == "R001"
    end

    test "returns an empty list when there are no matches", %{state: state} do
      assert {:ok, []} =
               ResourceManager.filter_by_category(state, :water)
    end

    test "rejects an invalid category", %{state: state} do
      assert {:error, :invalid_category} =
               ResourceManager.filter_by_category(state, :invalid)
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               ResourceManager.filter_by_category(%{}, :water)
    end
  end

  describe "filter_by_location/2" do
    test "returns resources matching the location", %{state: state} do
      {:ok, state, _resource1} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      {:ok, state, _resource2} =
        ResourceManager.register_resource(
          state,
          "R002",
          "Alimentos",
          :food,
          100,
          "unidades",
          "Z002",
          "Alimentos básicos"
        )

      assert {:ok, resources} =
               ResourceManager.filter_by_location(state, "Z001")

      assert length(resources) == 1
      assert hd(resources).code == "R001"
    end

    test "returns an empty list when there are no matches", %{state: state} do
      assert {:ok, []} =
               ResourceManager.filter_by_location(state, "Z001")
    end

    test "rejects an empty location", %{state: state} do
      assert {:error, :empty_fields} =
               ResourceManager.filter_by_location(state, " ")
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               ResourceManager.filter_by_location(%{}, "Z001")
    end
  end


describe "register_entry/4" do
  setup %{state: state} do
    {:ok, updated_state, _resource} =
      ResourceManager.register_resource(
        state,
        "R001",
        "Agua potable",
        :water,
        200,
        "litros",
        "Z001",
        "Agua para consumo"
      )

    %{state: updated_state}
  end

    test "registers an inventory entry", %{state: state} do
      {:ok, updated_state, movement} =
        ResourceManager.register_entry(state, "R001", "Z001", 50)

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 250
      assert movement.type == :entry
      assert movement.quantity == 50
      assert movement.previous_quantity == 200
      assert movement.new_quantity == 250
      assert movement.location == "Z001"
    end

    test "rejects a zero quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
              ResourceManager.register_entry(state, "R001", "Z001", 0)
    end

    test "rejects a negative quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
              ResourceManager.register_entry(state, "R001", "Z001", -10)
    end

    test "rejects a resource that does not exist", %{state: state} do
      assert {:error, :resource_not_found} =
              ResourceManager.register_entry(state, "R999", "Z001", 50)
    end

    test "rejects an empty resource code", %{state: state} do
      assert {:error, :empty_fields} =
              ResourceManager.register_entry(state, " ", "Z001", 50)
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
              ResourceManager.register_entry(%{}, "R001", "Z001", 50)
    end
  end

  describe "register_exit/4" do
    setup %{state: state} do
      {:ok, updated_state, _resource} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      %{state: updated_state}
    end

    test "registers an inventory exit", %{state: state} do
      assert {:ok, updated_state, movement} =
              ResourceManager.register_exit(state, "R001", "Z001", 50)

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 150
      assert movement.type == :exit
      assert movement.quantity == 50
      assert movement.previous_quantity == 200
      assert movement.new_quantity == 150
      assert movement.location == "Z001"
      assert length(updated_state.resource_movements) == 1
    end

    test "allows the inventory to reach zero", %{state: state} do
      assert {:ok, updated_state, _movement} =
              ResourceManager.register_exit(state, "R001", "Z001", 200)

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 0
    end

    test "rejects an exit greater than available inventory", %{state: state} do
      assert {:error, :insufficient_inventory} =
              ResourceManager.register_exit(state, "R001", "Z001", 250)

      assert state.resource_stocks[{"R001", "Z001"}] == 200
      assert state.resource_movements == []
    end

    test "rejects a zero quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
              ResourceManager.register_exit(state, "R001", "Z001", 0)
    end

    test "rejects a negative quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
              ResourceManager.register_exit(state, "R001", "Z001", -10)
    end

    test "rejects a resource that does not exist", %{state: state} do
      assert {:error, :resource_not_found} =
              ResourceManager.register_exit(state, "R999", "Z001", 50)
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
              ResourceManager.register_exit(%{}, "R001", "Z001", 50)
    end
  end


  describe "list_resource_movements/1" do
    test "returns all inventory movements", %{state: state} do
      {:ok, state, _resource} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      {:ok, state, _entry} =
        ResourceManager.register_entry(state, "R001", "Z001", 50)

      {:ok, state, _exit} =
        ResourceManager.register_exit(state, "R001", "Z001", 30)

      assert {:ok, movements} =
               ResourceManager.list_resource_movements(state)

      assert length(movements) == 2
      assert Enum.at(movements, 0).type == :entry
      assert Enum.at(movements, 1).type == :exit
    end

    test "returns an empty list when there are no movements", %{state: state} do
      assert {:ok, []} =
               ResourceManager.list_resource_movements(state)
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               ResourceManager.list_resource_movements(%{})
    end
  end

  describe "transfer_resource/5" do
    setup %{state: state} do
      {:ok, updated_state, _resource} =
        ResourceManager.register_resource(
          state,
          "R001",
          "Agua potable",
          :water,
          200,
          "litros",
          "Z001",
          "Agua para consumo"
        )

      %{state: updated_state}
    end

    test "transfers inventory between locations", %{state: state} do
      assert {:ok, updated_state, movement} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", 30
               )

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 170
      assert updated_state.resource_stocks[{"R001", "Z002"}] == 30

      assert movement.type == :transfer
      assert movement.resource_code == "R001"
      assert movement.origin == "Z001"
      assert movement.destination == "Z002"
      assert movement.quantity == 30

      assert movement.previous_origin_quantity == 200
      assert movement.new_origin_quantity == 170
      assert movement.previous_destination_quantity == 0
      assert movement.new_destination_quantity == 30

      assert length(updated_state.resource_movements) == 1
    end

    test "allows transferring all available inventory", %{state: state} do
      assert {:ok, updated_state, _movement} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", 200
               )

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 0
      assert updated_state.resource_stocks[{"R001", "Z002"}] == 200
    end

    test "adds transferred units to existing destination stock", %{state: state} do
      state =
        put_in(
          state.resource_stocks[{"R001", "Z002"}],
          50
        )

      assert {:ok, updated_state, _movement} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", 30
               )

      assert updated_state.resource_stocks[{"R001", "Z001"}] == 170
      assert updated_state.resource_stocks[{"R001", "Z002"}] == 80
    end

    test "rejects a transfer greater than available inventory", %{state: state} do
      assert {:error, :insufficient_inventory} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", 250
               )

      assert state.resource_stocks[{"R001", "Z001"}] == 200
      assert state.resource_stocks[{"R001", "Z002"}] == nil
      assert state.resource_movements == []
    end

    test "rejects a zero quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", 0
               )
    end

    test "rejects a negative quantity", %{state: state} do
      assert {:error, :invalid_quantity} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z002", -10
               )
    end

    test "rejects an empty resource code", %{state: state} do
      assert {:error, :empty_fields} =
               ResourceManager.transfer_resource(
                 state, " ", "Z001", "Z002", 30
               )
    end

    test "rejects an empty origin", %{state: state} do
      assert {:error, :empty_fields} =
               ResourceManager.transfer_resource(
                 state, "R001", " ", "Z002", 30
               )
    end

    test "rejects an empty destination", %{state: state} do
      assert {:error, :empty_fields} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", " ", 30
               )
    end

    test "rejects the same origin and destination", %{state: state} do
      assert {:error, :same_location} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z001", "Z001", 30
               )
    end

    test "rejects a resource that does not exist", %{state: state} do
      assert {:error, :resource_not_found} =
               ResourceManager.transfer_resource(
                 state, "R999", "Z001", "Z002", 30
               )
    end

    test "rejects an origin without registered stock", %{state: state} do
      assert {:error, :stock_not_found} =
               ResourceManager.transfer_resource(
                 state, "R001", "Z003", "Z002", 30
               )
    end

    test "rejects an invalid state" do
      assert {:error, :invalid_state} =
               ResourceManager.transfer_resource(
                 %{}, "R001", "Z001", "Z002", 30
               )
    end
  end

end
