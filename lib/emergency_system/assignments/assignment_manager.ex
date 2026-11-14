defmodule EmergencySystem.Assignments.AssignmentManager do
  @moduledoc """
  Módulo encargado de gestionar la asignación de recursos a las necesidades
  registradas en el sistema de emergencias.

  Coordina la gestión de necesidades y el inventario de recursos,
  verificando las cantidades disponibles y registrando cada asignación.

  ## Información del módulo

  - Versión: 1.0
  - Autores: Yvette Daniela Campo Osorio, Sofia Aviles Diaz,
    Santiago Barrero Lopez
  - Fecha: noviembre de 2026
  - Licencia: GNU GPL v3
  """

  # --------------------------------------------------
  # ASIGNACIÓN DE RECURSOS
  # --------------------------------------------------

  @doc """
  Asigna una cantidad de un recurso a una necesidad registrada.

  Verifica la disponibilidad del inventario, el tipo de recurso,
  el estado de la necesidad y la cantidad que aún necesita recibir.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `need_id`: identificador de la necesidad.
  - `resource_code`: código del recurso.
  - `location`: ubicación del inventario.
  - `quantity`: cantidad que se desea asignar.

  ## Retorna

  - `{:ok, updated_state, assignment}` si la asignación es exitosa.
  - `{:error, reason}` si ocurre una validación fallida.

  ## Ejemplo

      assign_resource(state, "N001", "R001", "centro_acopio_1", 30)
  """
  def assign_resource(state, need_id, resource_code, location, quantity) do
    stock_key = {resource_code, location}

    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_fields?(need_id, resource_code, location) ||
                   {:error, :empty_fields},
         true <- is_integer(quantity) and quantity > 0 ||
                   {:error, :invalid_quantity},
         {:ok, need} <- fetch_record(state.needs, need_id, :need_not_found),
         {:ok, resource} <-
           fetch_record(state.resources, resource_code, :resource_not_found),
         {:ok, available} <- fetch_stock(state.resource_stocks, stock_key),
         true <- valid_need_status?(need) || {:error, :invalid_need_status},
         true <- resource_matches_need?(resource, need) ||
                   {:error, :resource_type_mismatch},
         true <- quantity <= available || {:error, :insufficient_inventory},
         assigned_quantity <-
           assigned_quantity(state.resource_assignments, need_id),
         remaining_quantity <- need.quantity - assigned_quantity,
         true <- quantity <= remaining_quantity ||
                   {:error, :exceeds_need_quantity} do
      create_assignment(
        state,
        need,
        need_id,
        resource_code,
        location,
        quantity,
        stock_key,
        available
      )
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_arguments}
    end
  end

  # --------------------------------------------------
  # FUNCIONES AUXILIARES
  # --------------------------------------------------

  defp valid_state?(state) when is_map(state) do
    is_map(Map.get(state, :needs)) and
      is_map(Map.get(state, :resources)) and
      is_map(Map.get(state, :resource_stocks)) and
      is_list(Map.get(state, :resource_movements)) and
      is_list(Map.get(state, :resource_assignments))
  end

  defp valid_state?(_state), do: false

  defp valid_fields?(need_id, resource_code, location) do
    Enum.all?(
      [need_id, resource_code, location],
      fn field -> is_binary(field) and String.trim(field) != "" end
    )
  end

  defp fetch_record(records, id, error) do
    case Map.fetch(records, id) do
      {:ok, record} when is_map(record) -> {:ok, record}
      _ -> {:error, error}
    end
  end

  defp fetch_stock(stocks, stock_key) do
    case Map.fetch(stocks, stock_key) do
      {:ok, quantity} when is_integer(quantity) and quantity >= 0 ->
        {:ok, quantity}

      _ ->
        {:error, :stock_not_found}
    end
  end

  defp valid_need_status?(need) do
    Map.get(need, :status) in [:pending, :assigned] and
      is_integer(Map.get(need, :quantity)) and
      Map.get(need, :quantity) >= 0
  end

  defp resource_matches_need?(resource, need) do
    category = Map.get(resource, :category)
    type = Map.get(need, :type)

    is_atom(category) and is_binary(type) and
      Atom.to_string(category) == type
  end

  defp assigned_quantity(assignments, need_id) do
    assignments
    |> Enum.filter(fn assignment ->
      Map.get(assignment, :need_id) == need_id
    end)
    |> Enum.reduce(0, fn assignment, total ->
      quantity = Map.get(assignment, :quantity, 0)

      if is_integer(quantity) and quantity > 0 do
        total + quantity
      else
        total
      end
    end)
  end

  defp create_assignment(
         state,
         need,
         need_id,
         resource_code,
         location,
         quantity,
         stock_key,
         available
       ) do
    new_stock = available - quantity

    updated_need = Map.put(need, :status, :assigned)

    assignment = %{
      need_id: need_id,
      resource_code: resource_code,
      location: location,
      quantity: quantity,
      timestamp: DateTime.utc_now()
    }

    movement = %{
      type: :assignment,
      need_id: need_id,
      resource_code: resource_code,
      location: location,
      quantity: quantity,
      previous_quantity: available,
      new_quantity: new_stock,
      timestamp: DateTime.utc_now()
    }

    updated_state =
      state
      |> Map.put(
        :needs,
        Map.put(state.needs, need_id, updated_need)
      )
      |> Map.put(
        :resource_stocks,
        Map.put(state.resource_stocks, stock_key, new_stock)
      )
      |> Map.put(
        :resource_assignments,
        state.resource_assignments ++ [assignment]
      )
      |> Map.put(
        :resource_movements,
        state.resource_movements ++ [movement]
      )

    {:ok, updated_state, assignment}
  end

end
