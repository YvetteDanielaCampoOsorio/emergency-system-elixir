
defmodule EmergencySystem.Shelters.ShelterManager do
  @moduledoc """
  Gestiona el registro y consulta de albergues del sistema de emergencias.

  Permite registrar albergues y consultar su información.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  # ============================================================
  # REGISTRO DE ALBERGUES
  # ============================================================

  @doc """
  Registra un nuevo albergue en el sistema.

  ## Parámetros

  - state: estado actual del sistema.
  - code: código único del albergue.
  - name: nombre del albergue.
  - zone_code: código de la zona donde se encuentra.
  - capacity: capacidad máxima de personas.

  ## Retorna

  - {:ok, updated_state, shelter} si el registro es exitoso.
  - {:error, reason} si los datos son inválidos.
  """
  def register_shelter(state, code, name, zone_code, capacity) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(code) and valid_text?(name) and
                   valid_text?(zone_code) || {:error, :invalid_fields},
         true <- is_integer(capacity) and capacity > 0 ||
                   {:error, :invalid_capacity},
         true <- Map.has_key?(state.zones, zone_code) ||
                   {:error, :zone_not_found},
         true  <- not Map.has_key?(state.shelters, code) ||
                    {:error, :duplicate_shelter} do

      shelter = %{
        code: code,
        name: name,
        zone_code: zone_code,
        capacity: capacity,
        occupancy: 0
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
  # CONSULTA DE ALBERGUES
  # ============================================================

  @doc """
  Devuelve todos los albergues registrados.

  ## Parámetros

  - state: estado actual del sistema.

  ## Retorna

  - {:ok, shelters} con la lista de albergues.
  - {:error, :invalid_state} si el estado es inválido.
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

  ## Parámetros

  - state: estado actual del sistema.
  - code: código del albergue.

  ## Retorna

  - {:ok, shelter} si existe.
  - {:error, reason} si no existe o los datos son inválidos.
  """
  def get_shelter(state, code) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(code) || {:error, :invalid_code} do

      case Map.fetch(state.shelters, code) do
        {:ok, shelter} -> {:ok, shelter}
        :error -> {:error, :shelter_not_found}
      end
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # VALIDACIONES
  # ============================================================

  @doc false
  defp valid_state?(state) do
    is_map(state) and
      is_map(Map.get(state, :shelters)) and
      is_map(Map.get(state, :zones))
  end

  @doc false
  defp valid_text?(value) do
    is_binary(value) and String.trim(value) != ""
  end
end
