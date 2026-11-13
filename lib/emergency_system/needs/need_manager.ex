defmodule EmergencySystem.Needs.NeedManager do
  @moduledoc """
  Gestiona el registro y la consulta de las necesidades reportadas
  en las diferentes zonas afectadas por una emergencia.

  El módulo incluye funciones para:

  - Registrar nuevas necesidades en el sistema.
  - Consultar necesidades registradas.
  - Filtrar necesidades por zona, tipo, prioridad y estado.

  ## Información

  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  @valid_priorities [:critical, :high, :medium, :low]

  @valid_statuses [:pending, :assigned, :in_progress, :attended, :cancelled]

  @valid_transitions %{
    pending: [:assigned, :cancelled],
    assigned: [:pending, :in_progress, :cancelled],
    in_progress: [:attended, :cancelled],
    attended: [],
    cancelled: []
  }

  @priority_order %{
    critical: 1,
    high: 2,
    medium: 3,
    low: 4
  }

  # ==================================================
  # REGISTRO DE NECESIDADES
  # ==================================================

  @doc """
  Registra una nueva necesidad en el sistema.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `id`: identificador único de la necesidad.
  - `type`: tipo de necesidad reportada.
  - `description`: descripción de la necesidad.
  - `quantity`: cantidad solicitada.
  - `zone_code`: código de la zona donde se presenta la necesidad.
  - `priority`: nivel de prioridad de la necesidad.
  - `reporter`: nombre de usuario de quien reporta la necesidad.

  ## Retorno

  - `{:ok, updated_state, need}`: cuando la necesidad se registra correctamente.
  - `{:error, reason}`: cuando ocurre un error durante la validación o el registro.

  ## Posibles errores

  - `:invalid_arguments`: argumentos con tipos inválidos.
  - `:empty_fields`: existen campos obligatorios vacíos.
  - `:invalid_quantity`: cantidad negativa.
  - `:invalid_priority`: prioridad no válida.
  - `:invalid_state`: estado del sistema inválido.
  - `:need_already_exists`: el identificador ya está registrado.
  - `:zone_not_found`: la zona indicada no existe.
  - `:reporter_not_found`: el usuario que reporta no existe.

  ## Ejemplo

      register_need(state, "N001", "food", "Se necesitan alimentos",
        50, "Z001", :critical, "usuario1")
  """
  def register_need(state, id, type, description, quantity, zone_code, priority, reporter)
      when is_map(state) and is_binary(id) and is_binary(type) and
             is_binary(description) and is_integer(quantity) and
             is_binary(zone_code) and is_atom(priority) and is_binary(reporter) do
    cond do
      String.trim(id) == "" or String.trim(type) == "" or
        String.trim(description) == "" or String.trim(zone_code) == "" or
          String.trim(reporter) == "" ->
        {:error, :empty_fields}

      quantity < 0 ->
        {:error, :invalid_quantity}

      priority not in @valid_priorities ->
        {:error, :invalid_priority}

      not Map.has_key?(state, :needs) or
        not Map.has_key?(state, :zones) or
          not Map.has_key?(state, :users) ->
        {:error, :invalid_state}

      Map.has_key?(state.needs, id) ->
        {:error, :need_already_exists}

      not Map.has_key?(state.zones, zone_code) ->
        {:error, :zone_not_found}

      not Map.has_key?(state.users, reporter) ->
        {:error, :reporter_not_found}

      true ->
        need = %{
          id: id,
          type: type,
          description: description,
          quantity: quantity,
          zone_code: zone_code,
          priority: priority,
          reporter: reporter,
          status: :pending
        }

        updated_state = put_in(state, [:needs, id], need)

        {:ok, updated_state, need}
    end
  end

  def register_need(_state, _id, _type, _description, _quantity, _zone_code, _priority, _reporter) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # CONSULTA DE NECESIDADES
  # ==================================================

  @doc """
  Consulta todas las necesidades registradas en el sistema.

  ## Parámetros

  - `state`: estado actual del sistema que contiene el mapa de necesidades.

  ## Retorno

  - `{:ok, needs}`: lista con todas las necesidades registradas.
  - `{:error, :invalid_state}`: cuando el estado no es válido o no contiene un mapa de necesidades.

  ## Posibles errores

  - `:invalid_state`: el estado proporcionado no contiene la estructura de necesidades esperada.

  ## Ejemplo

      list_needs(state)
  """

  def list_needs(state) when is_map(state) do
    case Map.fetch(state, :needs) do
      {:ok, needs} when is_map(needs) ->
        {:ok, Map.values(needs)}

      _ ->
        {:error, :invalid_state}
    end
  end

  def list_needs(_state) do
    {:error, :invalid_state}
  end

  @doc """
  Consulta las necesidades registradas en una zona específica.

  ## Parámetros

  - `state`: estado actual del sistema que contiene las necesidades.
  - `zone_code`: código de la zona por la que se desea filtrar.

  ## Retorno

  - `{:ok, needs}`: lista de necesidades que pertenecen a la zona indicada.
  - `{:error, :empty_fields}`: cuando el código de zona está vacío.
  - `{:error, :invalid_state}`: cuando el estado no contiene un mapa de necesidades válido.
  - `{:error, :invalid_arguments}`: cuando los argumentos proporcionados no tienen los tipos esperados.

  ## Posibles errores

  - `:empty_fields`: el código de zona está vacío.
  - `:invalid_state`: el estado del sistema no es válido.
  - `:invalid_arguments`: los argumentos tienen tipos incorrectos.

  ## Ejemplo

      filter_by_zone(state, "Z001")
  """

  def filter_by_zone(state, zone_code)
      when is_map(state) and is_binary(zone_code) do
    cond do
      String.trim(zone_code) == "" ->
        {:error, :empty_fields}

      true ->
        case list_needs(state) do
          {:ok, needs} ->
            filtered =
              Enum.filter(needs, fn need ->
                need.zone_code == zone_code
              end)

            {:ok, filtered}

          error ->
            error
        end
    end
  end

  def filter_by_zone(_state, _zone_code) do
    {:error, :invalid_arguments}
  end

  @doc """
  Consulta las necesidades registradas según su tipo.

  ## Parámetros

  - `state`: estado actual del sistema que contiene las necesidades.
  - `type`: tipo de necesidad por el que se desea filtrar.

  ## Retorno

  - `{:ok, needs}`: lista de necesidades que coinciden con el tipo indicado.
  - `{:error, :empty_fields}`: cuando el tipo está vacío.
  - `{:error, :invalid_state}`: cuando el estado no contiene un mapa de necesidades válido.
  - `{:error, :invalid_arguments}`: cuando los argumentos tienen tipos incorrectos.

  ## Posibles errores

  - `:empty_fields`: el tipo de necesidad está vacío.
  - `:invalid_state`: el estado del sistema no es válido.
  - `:invalid_arguments`: los argumentos tienen tipos incorrectos.

  ## Ejemplo

      filter_by_type(state, "food")
  """

  def filter_by_type(state, type)
      when is_map(state) and is_binary(type) do
    cond do
      String.trim(type) == "" ->
        {:error, :empty_fields}

      true ->
        case list_needs(state) do
          {:ok, needs} ->
            filtered =
              Enum.filter(needs, fn need ->
                need.type == type
              end)

            {:ok, filtered}

          error ->
            error
        end
    end
  end

  def filter_by_type(_state, _type) do
    {:error, :invalid_arguments}
  end

  @doc """
  Consulta las necesidades registradas según su nivel de prioridad.

  ## Parámetros

  - `state`: estado actual del sistema que contiene las necesidades.
  - `priority`: nivel de prioridad por el que se desea filtrar.

  ## Retorno

  - `{:ok, needs}`: lista de necesidades que coinciden con la prioridad indicada.
  - `{:error, :invalid_priority}`: cuando la prioridad no es válida.
  - `{:error, :invalid_state}`: cuando el estado no contiene un mapa de necesidades válido.
  - `{:error, :invalid_arguments}`: cuando los argumentos tienen tipos incorrectos.

  ## Posibles errores

  - `:invalid_priority`: la prioridad no pertenece a los niveles permitidos.
  - `:invalid_state`: el estado del sistema no es válido.
  - `:invalid_arguments`: los argumentos tienen tipos incorrectos.

  ## Ejemplo

      filter_by_priority(state, :critical)
  """

  def filter_by_priority(state, priority)
      when is_map(state) and is_atom(priority) do
    cond do
      priority not in @valid_priorities ->
        {:error, :invalid_priority}

      true ->
        case list_needs(state) do
          {:ok, needs} ->
            filtered =
              Enum.filter(needs, fn need ->
                need.priority == priority
              end)

            {:ok, filtered}

          error ->
            error
        end
    end
  end

  def filter_by_priority(_state, _priority) do
    {:error, :invalid_arguments}
  end

  @doc """
  Consulta las necesidades registradas según su estado actual.

  ## Parámetros

  - `state`: estado actual del sistema que contiene las necesidades.
  - `status`: estado por el que se desea filtrar.

  ## Retorno

  - `{:ok, needs}`: lista de necesidades que coinciden con el estado indicado.
  - `{:error, :invalid_status}`: cuando el estado solicitado no es válido.
  - `{:error, :invalid_state}`: cuando el estado del sistema no contiene un mapa de necesidades válido.
  - `{:error, :invalid_arguments}`: cuando los argumentos tienen tipos incorrectos.

  ## Posibles errores

  - `:invalid_status`: el estado solicitado no pertenece a los estados permitidos.
  - `:invalid_state`: el estado del sistema no es válido.
  - `:invalid_arguments`: los argumentos tienen tipos incorrectos.

  ## Ejemplo

      filter_by_status(state, :pending)
  """

  def filter_by_status(state, status)
      when is_map(state) and is_atom(status) do
    cond do
      status not in @valid_statuses ->
        {:error, :invalid_status}

      true ->
        case list_needs(state) do
          {:ok, needs} ->
            filtered =
              Enum.filter(needs, fn need ->
                need.status == status
              end)

            {:ok, filtered}

          error ->
            error
        end
    end
  end

  def filter_by_status(_state, _status) do
    {:error, :invalid_arguments}
  end

  @doc """
  Ordena las necesidades registradas desde la prioridad más alta
  hasta la más baja.

  ## Parámetros
  - `state`: estado actual del sistema.

  ## Retorno
  - `{:ok, sorted_needs}` con las necesidades ordenadas por prioridad.
  - `{:error, reason}` si ocurre un error.

  ## Posibles errores
  - `:invalid_state`: estructura del estado incorrecta.
  - `:invalid_arguments`: argumento con tipo incorrecto.

  ## Ejemplo
      sort_by_priority(state)
  """
  def sort_by_priority(state) when is_map(state) do
    case list_needs(state) do
      {:ok, needs} ->
        sorted_needs =
          Enum.sort_by(needs, fn need ->
            Map.get(@priority_order, Map.get(need, :priority), 99)
          end)

        {:ok, sorted_needs}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def sort_by_priority(_state) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # GESTIÓN DE ESTADOS
  # ==================================================

  @doc """
  Actualiza el estado de una necesidad registrada, siempre que la transición
  solicitada esté permitida.

  ## Parámetros
  - `state`: estado actual del sistema.
  - `need_id`: identificador de la necesidad.
  - `new_status`: nuevo estado que se desea asignar.

  ## Retorno
  - `{:ok, updated_state, updated_need}` si la actualización fue exitosa.
  - `{:error, reason}` si ocurre un error.

  ## Posibles errores
  - `:invalid_arguments`: argumentos con tipos incorrectos.
  - `:empty_fields`: identificador vacío.
  - `:invalid_state`: estructura del estado incorrecta o estado actual inválido.
  - `:need_not_found`: la necesidad no existe.
  - `:invalid_status`: el nuevo estado no está permitido.
  - `:invalid_transition`: la transición no está permitida.

  ## Ejemplo
      update_need_status(state, "N001", :assigned)
  """
  def update_need_status(state, need_id, new_status)
      when is_map(state) and is_binary(need_id) and is_atom(new_status) do
    cond do
      String.trim(need_id) == "" ->
        {:error, :empty_fields}

      new_status not in @valid_statuses ->
        {:error, :invalid_status}

      true ->
        case Map.fetch(state, :needs) do
          {:ok, needs} when is_map(needs) ->
            case Map.fetch(needs, need_id) do
              {:ok, need} when is_map(need) ->
                case Map.fetch(need, :status) do
                  {:ok, current_status} ->
                    case Map.fetch(@valid_transitions, current_status) do
                      {:ok, allowed_statuses} ->
                        if new_status in allowed_statuses do
                          updated_need = Map.put(need, :status, new_status)
                          updated_needs = Map.put(needs, need_id, updated_need)
                          updated_state = Map.put(state, :needs, updated_needs)

                          {:ok, updated_state, updated_need}
                        else
                          {:error, :invalid_transition}
                        end

                      :error ->
                        {:error, :invalid_state}
                    end

                  :error ->
                    {:error, :invalid_state}
                end

              :error ->
                {:error, :need_not_found}

              _ ->
                {:error, :invalid_state}
            end

          _ ->
            {:error, :invalid_state}
        end
    end
  end

  def update_need_status(_state, _need_id, _new_status) do
    {:error, :invalid_arguments}
  end

  # ==================================================
  # FUNCIONES AUXILIARES
  # ==================================================
end
