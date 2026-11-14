
defmodule EmergencySystem.Pets.PetManager do
  @moduledoc """
  Gestiona los reportes de mascotas perdidas y encontradas durante
  una situación de emergencia.

  Permite registrar reportes y consultar la información de las mascotas.

  ## Autores

  - Yvette Daniela Campo Osorio
  - Sofia Aviles Diaz
  - Santiago Barrero Lopez

  Versión: 1.0
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  @valid_report_types [:lost, :found]
  @valid_statuses [:active, :possible_match, :resolved]

  # ============================================================
  # REGISTRO DE MASCOTAS
  # ============================================================

  @doc """
  Registra un reporte de una mascota perdida o encontrada.

  ## Parámetros

  - state: estado actual del sistema.
  - id: identificador único del reporte.
  - report_type: tipo de reporte (:lost o :found).
  - species: especie de la mascota.
  - name: nombre de la mascota, puede ser nil si se desconoce.
  - characteristics: descripción de sus características.
  - color: color de la mascota.
  - size: tamaño de la mascota.
  - zone_code: código de la zona donde fue reportada.
  - contact: información de contacto del reportante.

  ## Retorna

  - `{:ok, updated_state, pet}` si el registro es exitoso.
  - `{:error, reason}` si ocurre un error de validación.
  """
  def register_pet(
        state,
        id,
        report_type,
        species,
        name,
        characteristics,
        color,
        size,
        zone_code,
        contact
      ) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(id) || {:error, :invalid_id},
         true <- report_type in @valid_report_types ||
                   {:error, :invalid_report_type},
         true <- valid_text?(species) || {:error, :invalid_species},
         true <- valid_optional_text?(name) || {:error, :invalid_name},
         true <- valid_text?(characteristics) ||
                   {:error, :invalid_characteristics},
         true <- valid_text?(color) || {:error, :invalid_color},
         true <- valid_text?(size) || {:error, :invalid_size},
         true <- valid_text?(zone_code) || {:error, :invalid_zone},
         true <- valid_text?(contact) || {:error, :invalid_contact},
         true <- Map.has_key?(state.zones, zone_code) ||
                   {:error, :zone_not_found},
         true <- not Map.has_key?(state.pets, id) ||
                   {:error, :duplicate_pet} do

      pet = %{
        id: id,
        report_type: report_type,
        species: species,
        name: name,
        characteristics: characteristics,
        color: color,
        size: size,
        zone_code: zone_code,
        contact: contact,
        status: :active,
        timestamp: DateTime.utc_now()
      }

      updated_state = %{
        state |
        pets: Map.put(state.pets, id, pet)
      }

      {:ok, updated_state, pet}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # CONSULTA DE REPORTES DE MASCOTAS
  # ============================================================

  @doc """
  Consulta los reportes de mascotas aplicando filtros opcionales.

  ## Parámetros

  - state: estado actual del sistema.
  - filters: mapa con los filtros opcionales:
    - `:species`: especie de la mascota.
    - `:zone_code`: código de la zona.
    - `:status`: estado del reporte.

  ## Retorna

  - `{:ok, pets}` con los reportes encontrados.
  - `{:error, reason}` si los datos son inválidos.
  """
  def list_pets(state, filters \\ %{}) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- is_map(filters) || {:error, :invalid_filters},
         true <- valid_filters?(filters) || {:error, :invalid_filters} do

      pets =
        state.pets
        |> Map.values()
        |> Enum.filter(fn pet ->
          Enum.all?(filters, fn
            {:species, species} ->
              String.downcase(pet.species) == String.downcase(species)

            {:zone_code, zone_code} ->
              pet.zone_code == zone_code

            {:status, status} ->
              pet.status == status
          end)
        end)

      {:ok, pets}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_filters}
    end
  end

  # ============================================================
  # ACTUALIZACIÓN DEL ESTADO DE LOS REPORTES
  # ============================================================

  @doc """
  Actualiza el estado de un reporte de mascota.

  ## Parámetros

  - state: estado actual del sistema.
  - pet_id: identificador del reporte.
  - new_status: nuevo estado del reporte.

  ## Retorna

  - `{:ok, updated_state, updated_pet}` si la actualización es exitosa.
  - `{:error, reason}` si ocurre un error.
  """
  def update_pet_status(state, pet_id, new_status) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(pet_id) || {:error, :invalid_id},
         true <- new_status in @valid_statuses ||
                   {:error, :invalid_status},
         {:ok, pet} <- find_pet(state.pets, pet_id) do

      updated_pet = %{pet | status: new_status}

      updated_state = %{
        state |
        pets: Map.put(state.pets, pet_id, updated_pet)
      }

      {:ok, updated_state, updated_pet}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  defp find_pet(pets, pet_id) do
    case Map.fetch(pets, pet_id) do
      {:ok, pet} -> {:ok, pet}
      :error -> {:error, :pet_not_found}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp valid_state?(state) when is_map(state) do
    is_map(Map.get(state, :pets)) and
      is_map(Map.get(state, :zones))
  end

  defp valid_state?(_state), do: false

  defp valid_text?(value) do
    is_binary(value) and String.trim(value) != ""
  end

  defp valid_optional_text?(nil), do: true
  defp valid_optional_text?(value), do: valid_text?(value)

  defp valid_filters?(filters) do
    Enum.all?(filters, fn
      {:species, species} -> valid_text?(species)
      {:zone_code, zone_code} -> valid_text?(zone_code)
      {:status, status} -> status in @valid_statuses
      _ -> false
    end)
  end

end
