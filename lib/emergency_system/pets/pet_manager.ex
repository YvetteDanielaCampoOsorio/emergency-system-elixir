
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
  # ALGORITMO DE COINCIDENCIA DE MASCOTAS
  # ============================================================

  @doc """
  Calcula el porcentaje de similitud entre un reporte de mascota
  perdida y uno de mascota encontrada.

  La especie debe coincidir obligatoriamente. Se comparan el color,
  tamaño, características y nombre cuando está disponible.

  Retorna {:ok, score} con un puntaje entre 0 y 100,
  o {:error, reason} si los reportes no son compatibles.
  """

  def calculate_similarity(lost_pet, found_pet)
      when is_map(lost_pet) and is_map(found_pet) do
    with true <- valid_pet_report?(lost_pet) and valid_pet_report?(found_pet) ||
                   {:error, :invalid_report},
         true <- lost_pet.report_type == :lost ||
                   {:error, :invalid_report_type},
         true <- found_pet.report_type == :found ||
                   {:error, :invalid_report_type},
         true <- lost_pet.status != :resolved and found_pet.status != :resolved ||
                   {:error, :resolved_report},
         true <- same_species?(lost_pet, found_pet) ||
                   {:error, :different_species} do

      attributes = [
        {lost_pet.color, found_pet.color, 25},
        {lost_pet.size, found_pet.size, 20},
        {lost_pet.characteristics, found_pet.characteristics, 35},
        {lost_pet.name, found_pet.name, 20}
      ]

      available_attributes =
        Enum.filter(attributes, fn {first, second, _weight} ->
          not is_nil(first) and not is_nil(second)
        end)

      total_weight =
        Enum.reduce(available_attributes, 0, fn {_first, _second, weight}, total ->
          total + weight
        end)

      score =
        if total_weight == 0 do
          0
        else
          matched_weight =
            Enum.reduce(available_attributes, 0, fn {first, second, weight}, total ->
              if similar_text?(first, second), do: total + weight, else: total
            end)

          round(matched_weight / total_weight * 100)
        end

      {:ok, score}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_report}
    end
  end

  def calculate_similarity(_lost_pet, _found_pet) do
    {:error, :invalid_report}
  end

  defp valid_pet_report?(pet) do
    required_keys = [
      :report_type,
      :species,
      :name,
      :characteristics,
      :color,
      :size,
      :status
    ]

    Enum.all?(required_keys, &Map.has_key?(pet, &1)) and
      is_binary(pet.species) and
      is_binary(pet.color) and
      is_binary(pet.size) and
      is_binary(pet.characteristics) and
      (is_nil(pet.name) or is_binary(pet.name))
  end

  defp same_species?(first, second) do
    String.downcase(first.species) == String.downcase(second.species)
  end

  defp similar_text?(first, second) do
    String.downcase(String.trim(first)) ==
      String.downcase(String.trim(second))
  end

  # ============================================================
  # BÚSQUEDA DE POSIBLES COINCIDENCIAS
  # ============================================================

  @doc """
  Busca coincidencias entre reportes de mascotas perdidas
  y encontradas.

  ## Parámetros

  - state: estado actual del sistema.
  - min_score: porcentaje mínimo de similitud (por defecto 70).

  ## Retorna

  - {:ok, matches} con las coincidencias encontradas.
  - {:error, reason} si los parámetros son inválidos.
  """
  def find_possible_matches(state, min_score \\ 70) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- is_integer(min_score) and min_score >= 0 and min_score <= 100 ||
                   {:error, :invalid_score} do

      pets = Map.values(state.pets)

      lost_pets =
        Enum.filter(pets, fn pet ->
          pet.report_type == :lost and pet.status in [:active, :possible_match]
        end)

      found_pets =
        Enum.filter(pets, fn pet ->
          pet.report_type == :found and pet.status in [:active, :possible_match]
        end)

      matches =
        for lost_pet <- lost_pets,
            found_pet <- found_pets,
            {:ok, score} <- [calculate_similarity(lost_pet, found_pet)],
            score >= min_score do
          %{
            lost_pet_id: lost_pet.id,
            found_pet_id: found_pet.id,
            score: score
          }
        end
        |> Enum.sort_by(& &1.score, :desc)

      {:ok, matches}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_score}
    end
  end

  # ============================================================
  # CONFIRMACIÓN DE COINCIDENCIAS
  # ============================================================

  @doc """
  Confirma la coincidencia entre una mascota perdida y una encontrada.

  ## Parámetros

  - state: estado actual del sistema.
  - lost_pet_id: identificador del reporte de mascota perdida.
  - found_pet_id: identificador del reporte de mascota encontrada.

  ## Retorna

  - {:ok, updated_state, updated_lost_pet, updated_found_pet}
    si la coincidencia se confirma.
  - {:error, reason} si los reportes no son válidos.
  """

  def confirm_match(state, lost_pet_id, found_pet_id) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(lost_pet_id) and valid_text?(found_pet_id) ||
                   {:error, :invalid_id},
         true <- lost_pet_id != found_pet_id || {:error, :same_report},
         {:ok, lost_pet} <- find_pet(state.pets, lost_pet_id),
         {:ok, found_pet} <- find_pet(state.pets, found_pet_id),
         true <- lost_pet.report_type == :lost || {:error, :invalid_lost_report},
         true <- found_pet.report_type == :found || {:error, :invalid_found_report},
         true <- lost_pet.status != :resolved and found_pet.status != :resolved ||
                   {:error, :resolved_report} do

      updated_lost_pet = %{lost_pet | status: :resolved}
      updated_found_pet = %{found_pet | status: :resolved}

      updated_pets =
        state.pets
        |> Map.put(lost_pet_id, updated_lost_pet)
        |> Map.put(found_pet_id, updated_found_pet)

      updated_state = %{state | pets: updated_pets}

      {:ok, updated_state, updated_lost_pet, updated_found_pet}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
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
