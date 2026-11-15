defmodule EmergencySystem.Shelters.ShelterManager do
  @moduledoc """
  Gestiona el registro, consulta y ocupación de los albergues.

  Permite registrar albergues, controlar ingresos y salidas de personas
  y consultar los cupos disponibles.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  alias EmergencySystem.People.PersonManager

  # ============================================================
  # REGISTRO DE ALBERGUES
  # ============================================================

  @doc """
  Registra un nuevo albergue en el sistema.
  """
  def register_shelter(state, code, name, zone_code, capacity) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <-
           (valid_text?(code) and valid_text?(name) and
              valid_text?(zone_code)) || {:error, :invalid_fields},
         true <-
           (is_integer(capacity) and capacity > 0) ||
             {:error, :invalid_capacity},
         true <-
           Map.has_key?(state.zones, zone_code) ||
             {:error, :zone_not_found},
         true <-
           not Map.has_key?(state.shelters, code) ||
             {:error, :duplicate_shelter} do
      shelter = %{
        code: code,
        name: name,
        zone_code: zone_code,
        capacity: capacity,
        occupancy: 0,
        occupants: MapSet.new()
      }

      updated_shelters = Map.put(state.shelters, code, shelter)
      updated_state = %{state | shelters: updated_shelters}

      {:ok, updated_state, shelter}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # INGRESO DE PERSONAS
  # ============================================================

  @doc """
  Registra el ingreso de una persona a un albergue.

  La persona debe existir y tener un estado que permita su ingreso.
  No se permiten ingresos duplicados ni superar la capacidad.
  """
  def register_entry(state, shelter_code, document) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <-
           (valid_text?(shelter_code) and valid_text?(document)) ||
             {:error, :invalid_fields},
         {:ok, shelter} <- find_shelter(state, shelter_code),
         {:ok, person} <- find_person_by_document(state, document),
         true <-
           not MapSet.member?(shelter.occupants, document) ||
             {:error, :person_already_inside},
         true <-
           shelter.occupancy < shelter.capacity ||
             {:error, :shelter_full},
         {:ok, person_state, updated_person} <-
           PersonManager.update_person_status(
             state,
             person.id,
             :in_shelter
           ) do
      updated_shelter = %{
        shelter
        | occupancy: shelter.occupancy + 1,
          occupants: MapSet.put(shelter.occupants, document)
      }

      updated_shelters =
        Map.put(person_state.shelters, shelter_code, updated_shelter)

      updated_state = %{person_state | shelters: updated_shelters}

      {:ok, updated_state, updated_shelter, updated_person}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_entry}
    end
  end

  # ============================================================
  # SALIDA DE PERSONAS
  # ============================================================

  @doc """
  Registra la salida de una persona de un albergue.

  El estado final debe ser :transferred o :reunified.
  """
  def register_exit(state, shelter_code, document, destination_status) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <-
           (valid_text?(shelter_code) and valid_text?(document)) ||
             {:error, :invalid_fields},
         true <-
           destination_status in [:transferred, :reunified] ||
             {:error, :invalid_destination_status},
         {:ok, shelter} <- find_shelter(state, shelter_code),
         true <-
           MapSet.member?(shelter.occupants, document) ||
             {:error, :person_not_in_shelter},
         {:ok, person} <- find_person_by_document(state, document),
         {:ok, person_state, updated_person} <-
           PersonManager.update_person_status(
             state,
             person.id,
             destination_status
           ) do
      updated_shelter = %{
        shelter
        | occupancy: shelter.occupancy - 1,
          occupants: MapSet.delete(shelter.occupants, document)
      }

      updated_shelters =
        Map.put(person_state.shelters, shelter_code, updated_shelter)

      updated_state = %{person_state | shelters: updated_shelters}

      {:ok, updated_state, updated_shelter, updated_person}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_exit}
    end
  end

  # ============================================================
  # CONSULTA DE ALBERGUES Y CUPOS
  # ============================================================

  @doc """
  Devuelve todos los albergues registrados.
  """
  def list_shelters(state) do
    if valid_state?(state) do
      {:ok, Map.values(state.shelters)}
    else
      {:error, :invalid_state}
    end
  end

  @doc """
  Busca un albergue por su código.
  """
  def get_shelter(state, code) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(code) || {:error, :invalid_code} do
      find_shelter(state, code)
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  @doc """
  Consulta la cantidad de cupos disponibles en un albergue.
  """
  def available_capacity(state, shelter_code) do
    with {:ok, shelter} <- get_shelter(state, shelter_code) do
      {:ok, shelter.capacity - shelter.occupancy}
    end
  end

  @doc """
  Consulta la información de un albergue y sus cupos disponibles.
  """
  def check_shelter(state, shelter_code) do
    with {:ok, shelter} <- get_shelter(state, shelter_code) do
      {:ok,
       Map.put(
         shelter,
         :available_capacity,
         shelter.capacity - shelter.occupancy
       )}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp find_shelter(state, shelter_code) do
    case Map.fetch(state.shelters, shelter_code) do
      {:ok, shelter} -> {:ok, shelter}
      :error -> {:error, :shelter_not_found}
    end
  end

  @doc false
  defp find_person_by_document(state, document) do
    case Enum.find(
           Map.values(state.people),
           fn person -> person.reference == document end
         ) do
      nil -> {:error, :person_not_found}
      person -> {:ok, person}
    end
  end

  @doc false
  defp valid_state?(state) do
    is_map(state) and
      is_map(Map.get(state, :shelters)) and
      is_map(Map.get(state, :zones)) and
      is_map(Map.get(state, :people)) and
      is_list(Map.get(state, :person_status_history))
  end

  @doc false
  defp valid_text?(value) do
    is_binary(value) and String.trim(value) != ""
  end
end
