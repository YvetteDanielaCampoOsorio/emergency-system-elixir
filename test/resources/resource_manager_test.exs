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
      assert resource.quantity == 200
      assert resource.category == :water
      assert updated_state.resources["R001"] == resource
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
end
