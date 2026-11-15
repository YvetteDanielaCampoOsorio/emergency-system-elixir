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
  Registra un nuevo recurso y sus existencias iniciales en una ubicación.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `code`: código único del recurso.
  - `name`: nombre del recurso.
  - `category`: categoría del recurso.
  - `quantity`: cantidad inicial disponible.
  - `unit`: unidad de medida.
  - `location`: ubicación inicial del recurso.
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
        case {Map.fetch(state, :resources), Map.fetch(state, :resource_stocks)} do
          {{:ok, resources}, {:ok, stocks}}
          when is_map(resources) and is_map(stocks) ->
            if Map.has_key?(resources, code) do
              {:error, :resource_already_exists}
            else
              resource = %{
                code: code,
                name: name,
                category: category,
                unit: unit,
                description: description
              }

              updated_resources = Map.put(resources, code, resource)
              updated_stocks = Map.put(stocks, {code, location}, quantity)

              updated_state =
                state
                |> Map.put(:resources, updated_resources)
                |> Map.put(:resource_stocks, updated_stocks)

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
  # MOVIMIENTOS DE INVENTARIO
  # ==================================================

  @doc """
  Registra una entrada de unidades al inventario de un recurso
  en una ubicación específica.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `resource_code`: código del recurso.
  - `location`: ubicación que recibe las unidades.
  - `quantity`: cantidad de unidades que ingresarán.

  ## Retorna
  - `{:ok, updated_state, movement}` si la entrada es exitosa.
  - `{:error, reason}` si ocurre un error.

  ## Ejemplo

      iex> ResourceManager.register_entry(state, "R001", "Z001", 50)
      {:ok, updated_state, movement}
  """
  def register_entry(state, resource_code, location, quantity)
      when is_map(state) and is_binary(resource_code) and
             is_binary(location) and is_integer(quantity) do
    cond do
      String.trim(resource_code) == "" or String.trim(location) == "" ->
        {:error, :empty_fields}

      quantity <= 0 ->
        {:error, :invalid_quantity}

      true ->
        case {
          Map.fetch(state, :resources),
          Map.fetch(state, :resource_stocks),
          Map.fetch(state, :resource_movements)
        } do
          {{:ok, resources}, {:ok, stocks}, {:ok, movements}}
          when is_map(resources) and is_map(stocks) and is_list(movements) ->
            stock_key = {resource_code, location}

            cond do
              not Map.has_key?(resources, resource_code) ->
                {:error, :resource_not_found}

              not Map.has_key?(stocks, stock_key) ->
                {:error, :stock_not_found}

              true ->
                previous_quantity = Map.fetch!(stocks, stock_key)
                new_quantity = previous_quantity + quantity

                movement = %{
                  type: :entry,
                  resource_code: resource_code,
                  location: location,
                  quantity: quantity,
                  previous_quantity: previous_quantity,
                  new_quantity: new_quantity,
                  timestamp: DateTime.utc_now()
                }

                updated_state =
                  state
                  |> Map.put(
                    :resource_stocks,
                    Map.put(stocks, stock_key, new_quantity)
                  )
                  |> Map.put(:resource_movements, movements ++ [movement])

                {:ok, updated_state, movement}
            end

          _ ->
            {:error, :invalid_state}
        end
    end
  end

  def register_entry(_state, _resource_code, _location, _quantity),
    do: {:error, :invalid_arguments}

  @doc """
  Registra una salida de unidades del inventario de un recurso
  desde una ubicación específica.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `resource_code`: código del recurso.
  - `location`: ubicación de donde saldrán las unidades.
  - `quantity`: cantidad de unidades que se retirarán.

  ## Retorna
  - `{:ok, updated_state, movement}` si la salida es exitosa.
  - `{:error, reason}` si ocurre un error.
  """
  def register_exit(state, resource_code, location, quantity)
      when is_map(state) and is_binary(resource_code) and
             is_binary(location) and is_integer(quantity) do
    cond do
      String.trim(resource_code) == "" or String.trim(location) == "" ->
        {:error, :empty_fields}

      quantity <= 0 ->
        {:error, :invalid_quantity}

      true ->
        case {
          Map.fetch(state, :resources),
          Map.fetch(state, :resource_stocks),
          Map.fetch(state, :resource_movements)
        } do
          {{:ok, resources}, {:ok, stocks}, {:ok, movements}}
          when is_map(resources) and is_map(stocks) and is_list(movements) ->
            stock_key = {resource_code, location}

            cond do
              not Map.has_key?(resources, resource_code) ->
                {:error, :resource_not_found}

              not Map.has_key?(stocks, stock_key) ->
                {:error, :stock_not_found}

              true ->
                previous_quantity = Map.fetch!(stocks, stock_key)

                if quantity > previous_quantity do
                  {:error, :insufficient_inventory}
                else
                  new_quantity = previous_quantity - quantity

                  movement = %{
                    type: :exit,
                    resource_code: resource_code,
                    location: location,
                    quantity: quantity,
                    previous_quantity: previous_quantity,
                    new_quantity: new_quantity,
                    timestamp: DateTime.utc_now()
                  }

                  updated_state =
                    state
                    |> Map.put(
                      :resource_stocks,
                      Map.put(stocks, stock_key, new_quantity)
                    )
                    |> Map.put(:resource_movements, movements ++ [movement])

                  {:ok, updated_state, movement}
                end
            end

          _ ->
            {:error, :invalid_state}
        end
    end
  end

  def register_exit(_state, _resource_code, _location, _quantity),
    do: {:error, :invalid_arguments}

  @doc """
  Transfiere unidades de un recurso entre dos ubicaciones.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `resource_code`: código del recurso que se transferirá.
  - `origin`: ubicación de origen.
  - `destination`: ubicación de destino.
  - `quantity`: cantidad de unidades que se transferirán.

  ## Retorna
  - `{:ok, updated_state, movement}` si la transferencia es exitosa.
  - `{:error, reason}` si ocurre un error.

  ## Ejemplo

      iex> ResourceManager.transfer_resource(
      ...>   state, "R001", "Z001", "Z002", 30
      ...> )
      {:ok, updated_state, movement}
  """
  def transfer_resource(state, resource_code, origin, destination, quantity)
      when is_map(state) and is_binary(resource_code) and
             is_binary(origin) and is_binary(destination) and
             is_integer(quantity) do
    cond do
      String.trim(resource_code) == "" or
        String.trim(origin) == "" or
          String.trim(destination) == "" ->
        {:error, :empty_fields}

      origin == destination ->
        {:error, :same_location}

      quantity <= 0 ->
        {:error, :invalid_quantity}

      true ->
        case {
          Map.fetch(state, :resources),
          Map.fetch(state, :resource_stocks),
          Map.fetch(state, :resource_movements)
        } do
          {{:ok, resources}, {:ok, stocks}, {:ok, movements}}
          when is_map(resources) and is_map(stocks) and is_list(movements) ->
            origin_key = {resource_code, origin}
            destination_key = {resource_code, destination}

            cond do
              not Map.has_key?(resources, resource_code) ->
                {:error, :resource_not_found}

              not Map.has_key?(stocks, origin_key) ->
                {:error, :stock_not_found}

              true ->
                origin_quantity = Map.fetch!(stocks, origin_key)

                if quantity > origin_quantity do
                  {:error, :insufficient_inventory}
                else
                  destination_quantity = Map.get(stocks, destination_key, 0)

                  updated_stocks =
                    stocks
                    |> Map.put(origin_key, origin_quantity - quantity)
                    |> Map.put(destination_key, destination_quantity + quantity)

                  movement = %{
                    type: :transfer,
                    resource_code: resource_code,
                    origin: origin,
                    destination: destination,
                    quantity: quantity,
                    previous_origin_quantity: origin_quantity,
                    new_origin_quantity: origin_quantity - quantity,
                    previous_destination_quantity: destination_quantity,
                    new_destination_quantity: destination_quantity + quantity,
                    timestamp: DateTime.utc_now()
                  }

                  updated_state =
                    state
                    |> Map.put(:resource_stocks, updated_stocks)
                    |> Map.put(:resource_movements, movements ++ [movement])

                  {:ok, updated_state, movement}
                end
            end

          _ ->
            {:error, :invalid_state}
        end
    end
  end

  def transfer_resource(
        _state,
        _resource_code,
        _origin,
        _destination,
        _quantity
      ),
      do: {:error, :invalid_arguments}

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
  Consulta los recursos disponibles en una ubicación específica.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `location`: código o nombre de la ubicación que se desea consultar.

  ## Retorna
  - `{:ok, resources}` con los recursos encontrados, incluyendo su ubicación
    y cantidad disponible.
  - `{:error, reason}` si ocurre un error.

  ## Ejemplo

      iex> ResourceManager.filter_by_location(state, "Z001")
      {:ok, [%{code: "R001", name: "Agua potable", quantity: 200,
               location: "Z001", ...}]}
  """
  def filter_by_location(state, location)
      when is_map(state) and is_binary(location) do
    if String.trim(location) == "" do
      {:error, :empty_fields}
    else
      case {
        Map.fetch(state, :resources),
        Map.fetch(state, :resource_stocks)
      } do
        {{:ok, resources}, {:ok, stocks}}
        when is_map(resources) and is_map(stocks) ->
          filtered_resources =
            Enum.reduce(stocks, [], fn
              {{resource_code, stock_location}, quantity}, acc
              when stock_location == location ->
                case Map.fetch(resources, resource_code) do
                  {:ok, resource} ->
                    resource_with_stock =
                      Map.merge(resource, %{
                        location: stock_location,
                        quantity: quantity
                      })

                    [resource_with_stock | acc]

                  :error ->
                    acc
                end

              _, acc ->
                acc
            end)
            |> Enum.reverse()

          {:ok, filtered_resources}

        _ ->
          {:error, :invalid_state}
      end
    end
  end

  def filter_by_location(_state, _location),
    do: {:error, :invalid_arguments}

  @doc """
  Consulta el historial de movimientos del inventario.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorna
  - `{:ok, movements}`: lista de movimientos registrados.
  - `{:error, :invalid_state}`: si el estado no contiene un historial válido.
  """
  def list_resource_movements(state) when is_map(state) do
    case Map.fetch(state, :resource_movements) do
      {:ok, movements} when is_list(movements) ->
        {:ok, movements}

      _ ->
        {:error, :invalid_state}
    end
  end

  def list_resource_movements(_state), do: {:error, :invalid_state}

  # ==================================================
  # FUNCIONES AUXILIARES
  # ==================================================
end
