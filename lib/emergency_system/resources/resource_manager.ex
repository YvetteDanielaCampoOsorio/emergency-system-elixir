defmodule EmergencySystem.Resources.ResourceManager do
  @moduledoc """
  Gestiona el registro y la consulta de los recursos disponibles
  para la atención de emergencias.

  El módulo incluye funciones para:
  - Registrar nuevos recursos.
  - Consultar los recursos registrados.
  - Consultar la disponibilidad por tipo y zona.

  ## Información
  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  @valid_categories [
    :water,
    :food,
    :medicine,
    :first_aid,
    :shelter,
    :transport,
    :rescue,
    :other
  ]

  # ==================================================
  # REGISTRO DE RECURSOS
  # ==================================================

  @doc """
  Registra un nuevo recurso en el sistema.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `code`: código único del recurso.
  - `name`: nombre del recurso.
  - `category`: categoría del recurso.
  - `quantity`: cantidad disponible.
  - `unit`: unidad de medida.
  - `location`: ubicación del recurso.
  - `description`: descripción del recurso.

  ## Retorno
  - `{:ok, updated_state, resource}` si el registro fue exitoso.
  - `{:error, reason}` si ocurre un error.

  ## Posibles errores
  - `:invalid_arguments`
  - `:empty_fields`
  - `:invalid_quantity`
  - `:invalid_category`
  - `:invalid_state`
  - `:resource_already_exists`

  ## Ejemplo
      register_resource(state, "R001", "Agua potable", :water, 200,
        "litros", "Z001", "Agua para consumo humano")
  """
  def register_resource(
        state,
        code,
        name,
        category,
        quantity,
        unit,
        location,
        description
      )
      when is_map(state) and is_binary(code) and is_binary(name) and
             is_atom(category) and is_integer(quantity) and is_binary(unit) and
             is_binary(location) and is_binary(description) do
    cond do
      String.trim(code) == "" or String.trim(name) == "" or
        String.trim(unit) == "" or String.trim(location) == "" or
          String.trim(description) == "" ->
        {:error, :empty_fields}

      quantity < 0 ->
        {:error, :invalid_quantity}

      category not in @valid_categories ->
        {:error, :invalid_category}

      true ->
        case Map.fetch(state, :resources) do
          {:ok, resources} when is_map(resources) ->
            if Map.has_key?(resources, code) do
              {:error, :resource_already_exists}
            else
              resource = %{
                code: code,
                name: name,
                category: category,
                quantity: quantity,
                unit: unit,
                location: location,
                description: description
              }

              updated_resources = Map.put(resources, code, resource)
              updated_state = Map.put(state, :resources, updated_resources)

              {:ok, updated_state, resource}
            end

          _ ->
            {:error, :invalid_state}
        end
    end
  end

  def register_resource(
        _state,
        _code,
        _name,
        _category,
        _quantity,
        _unit,
        _location,
        _description
      ) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # CONSULTA DE RECURSOS
  # ==================================================

  @doc """
  Consulta todos los recursos registrados en el sistema.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorna
  - `{:ok, resources}`: lista de recursos registrados.
  - `{:error, :invalid_state}`: si el estado no contiene una estructura válida de recursos.

  ## Ejemplo
      iex> ResourceManager.list_resources(state)
      {:ok, [%{code: "R001", name: "Agua potable"}]}
  """
  def list_resources(state) when is_map(state) do
    case Map.fetch(state, :resources) do
      {:ok, resources} when is_map(resources) ->
        {:ok, Map.values(resources)}

      _ ->
        {:error, :invalid_state}
    end
  end

  def list_resources(_state), do: {:error, :invalid_state}

  @doc """
  Consulta los recursos registrados según su categoría.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `category`: categoría de los recursos que se desean consultar.

  ## Retorna
  - `{:ok, resources}`: lista de recursos que coinciden con la categoría.
  - `{:error, :invalid_category}`: si la categoría no es válida.
  - `{:error, :invalid_state}`: si el estado no contiene recursos válidos.
  - `{:error, :invalid_arguments}`: si los argumentos tienen tipos incorrectos.

  ## Ejemplo
      iex> ResourceManager.filter_by_category(state, :water)
      {:ok, [%{code: "R001", category: :water}]}
  """
  def filter_by_category(state, category)
      when is_map(state) and is_atom(category) do
    if category in @valid_categories do
      case Map.fetch(state, :resources) do
        {:ok, resources} when is_map(resources) ->
          filtered_resources =
            resources
            |> Map.values()
            |> Enum.filter(fn resource -> resource.category == category end)

          {:ok, filtered_resources}

        _ ->
          {:error, :invalid_state}
      end
    else
      {:error, :invalid_category}
    end
  end

  def filter_by_category(_state, _category), do: {:error, :invalid_arguments}

  @doc """
  Consulta los recursos registrados según su ubicación.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `location`: código o nombre de la ubicación que se desea consultar.

  ## Retorna
  - `{:ok, resources}`: lista de recursos encontrados.
  - `{:error, :empty_fields}`: si la ubicación está vacía.
  - `{:error, :invalid_state}`: si el estado no contiene recursos válidos.
  - `{:error, :invalid_arguments}`: si los argumentos tienen tipos incorrectos.

  ## Ejemplo
      iex> ResourceManager.filter_by_location(state, "Z001")
      {:ok, [%{code: "R001", location: "Z001"}]}
  """
  def filter_by_location(state, location)
      when is_map(state) and is_binary(location) do
    if String.trim(location) == "" do
      {:error, :empty_fields}
    else
      case Map.fetch(state, :resources) do
        {:ok, resources} when is_map(resources) ->
          filtered_resources =
            resources
            |> Map.values()
            |> Enum.filter(fn resource -> resource.location == location end)

          {:ok, filtered_resources}

        _ ->
          {:error, :invalid_state}
      end
    end
  end

  def filter_by_location(_state, _location), do: {:error, :invalid_arguments}

  # ==================================================
  # FUNCIONES AUXILIARES
  # ==================================================
end
