
defmodule EmergencySystem.Reports.Summary do
  @moduledoc """
  Genera consultas y reportes generales sobre el estado del
  Sistema Distribuido de Coordinación y Gestión de Emergencias.

  El módulo permite consultar las necesidades pendientes,
  identificar recursos agotados y obtener estadísticas
  generales de la emergencia.

  ## Información

  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  alias EmergencySystem.Needs.NeedManager

  # ==================================================
  # CONSULTA DE NECESIDADES PENDIENTES
  # ==================================================

  @doc """
  Consulta las necesidades que todavía están pendientes
  de atención.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorno
  - `{:ok, needs}`: lista de necesidades pendientes.
  - `{:error, reason}`: si ocurre un error.

  ## Ejemplo
      pending_needs(state)
  """
  def pending_needs(state) when is_map(state) do
    NeedManager.filter_by_status(state, :pending)
  end

  def pending_needs(_state) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # CONSULTA DE RECURSOS CRÍTICOS
  # ==================================================

  @doc """
  Identifica los recursos que no tienen existencias
  disponibles en sus ubicaciones.

  Se considera crítico un recurso cuya cantidad disponible
  sea igual a cero.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorno
  - `{:ok, resources}`: lista de recursos agotados.
  - `{:error, :invalid_state}`: estructura de inventario inválida.

  ## Ejemplo
      critical_resources(state)
  """
  def critical_resources(state) when is_map(state) do
    case {
      Map.fetch(state, :resources),
      Map.fetch(state, :resource_stocks)
    } do
      {{:ok, resources}, {:ok, stocks}}
      when is_map(resources) and is_map(stocks) ->

        critical =
          Enum.reduce(stocks, [], fn
            {{resource_code, location}, quantity}, acc
            when is_integer(quantity) and quantity == 0 ->

              case Map.fetch(resources, resource_code) do
                {:ok, resource} ->
                  item = Map.merge(resource, %{
                    location: location,
                    quantity: quantity
                  })

                  [item | acc]

                :error ->
                  acc
              end

            _, acc ->
              acc
          end)

        {:ok, Enum.reverse(critical)}

      _ ->
        {:error, :invalid_state}
    end
  end

  def critical_resources(_state) do
    {:error, :invalid_state}
  end
  # ==================================================
  # RESUMEN GENERAL DE LA EMERGENCIA
  # ==================================================

  @doc """
  Genera un resumen estadístico completo del estado
  del sistema de emergencias.

  Incluye cantidades generales y detalles sobre recursos,
  necesidades, personas, mensajes, mascotas y albergues.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorno
  - `{:ok, summary}`: mapa con las estadísticas generales.
  - `{:error, reason}`: si el estado es inválido.

  ## Ejemplo
      summary(state)
  """
  def summary(state) when is_map(state) do
    with true <- valid_summary_state?(state),
         {:ok, pending} <- pending_needs(state),
         {:ok, critical} <- critical_resources(state) do

      people = Map.values(state.people)
      pets = Map.values(state.pets)
      shelters = Map.values(state.shelters)

      located_people =
        Enum.filter(people, &(&1.status == :located))

      pending_messages =
        Enum.filter(state.messages, &(&1.status == :pending))

      active_pets =
        Enum.filter(pets, &(&1.status == :active))

      total_resources =
        Enum.reduce(state.resource_stocks, 0, fn
          {_location, quantity}, total
          when is_number(quantity) and quantity >= 0 ->
            total + quantity

          _, total ->
            total
        end)

      total_occupancy =
        Enum.reduce(shelters, 0, fn shelter, total ->
          total + shelter.occupancy
        end)

      total_capacity =
        Enum.reduce(shelters, 0, fn shelter, total ->
          total + shelter.capacity
        end)

      result = %{
        zones_count: map_size(state.zones),
        needs_count: map_size(state.needs),
        pending_needs_count: length(pending),
        pending_needs: pending,
        resources_count: map_size(state.resources),
        total_resources_remaining: total_resources,
        critical_resources_count: length(critical),
        critical_resources: critical,
        people_count: map_size(state.people),
        located_people: located_people,
        messages_count: length(state.messages),
        pending_messages: length(pending_messages),
        pets_count: map_size(state.pets),
        active_pet_reports: length(active_pets),
        total_pet_reports: length(pets),
        shelters_count: map_size(state.shelters),
        shelter_occupancy: total_occupancy,
        shelter_capacity: total_capacity,
        active_users_count: MapSet.size(state.active_users),
        resource_movements_count: length(state.resource_movements),
        resource_assignments_count: length(state.resource_assignments)
      }

      {:ok, result}
    else
      false -> {:error, :invalid_state}
      {:error, reason} -> {:error, reason}
    end
  end

  def summary(_state) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # VALIDACIÓN DEL ESTADO
  # ==================================================

  defp valid_summary_state?(state) do
    map_keys = [
      :users,
      :zones,
      :needs,
      :resources,
      :resource_stocks,
      :people,
      :pets,
      :shelters
    ]

    list_keys = [
      :messages,
      :resource_movements,
      :resource_assignments
    ]

    Enum.all?(map_keys, fn key ->
      is_map(Map.get(state, key))
    end) and
      Enum.all?(list_keys, fn key ->
        is_list(Map.get(state, key))
      end) and
      match?(%MapSet{}, Map.get(state, :active_users))
  end

end
