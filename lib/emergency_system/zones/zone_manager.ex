defmodule EmergencySystem.Zones.ZoneManager do
  @moduledoc """
  Gestiona las zonas afectadas por la emergencia.

  Permite registrar zonas, sectores y puntos de atención,
  así como consultar su información y estado general.

   ## Información

  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  alias EmergencySystem.Data

  @valid_impact_levels [:critical, :high, :medium, :low]

  # --------------------------------------------------
  # Registro de zonas
  # --------------------------------------------------

  @doc """
  Registra una nueva zona afectada por la emergencia.

  ## Parámetros
  - `state`: estado general del sistema.
  - `code`: código único de la zona.
  - `name`: nombre de la zona.
  - `impact_level`: nivel de afectación.
  - `estimated_people`: cantidad estimada de personas afectadas.

  ## Retorna
  - `{:ok, updated_state, zone}` si el registro es exitoso.
  - `{:error, reason}` si ocurre una validación incorrecta.

  ## Posibles errores
  - `:invalid_arguments`: argumentos inválidos.
  - `:empty_fields`: código o nombre vacío.
  - `:zone_already_exists`: el código ya está registrado.
  - `:invalid_impact_level`: nivel de afectación no permitido.
  - `:invalid_people_count`: cantidad de personas inválida.

  ## Ejemplo
      create_zone(state, "Z001", "Centro", :high, 250)
  """
  def create_zone(state, code, name, impact_level, estimated_people)
      when is_map(state) and is_binary(code) and is_binary(name) do
    cond do
      String.trim(code) == "" or String.trim(name) == "" ->
        {:error, :empty_fields}

      Map.has_key?(state.zones, code) ->
        {:error, :zone_already_exists}

      impact_level not in @valid_impact_levels ->
        {:error, :invalid_impact_level}

      not (is_integer(estimated_people) and estimated_people >= 0) ->
        {:error, :invalid_people_count}

      true ->
        zone = Data.new_zone(code, name, impact_level, estimated_people)
        updated_state = put_in(state.zones[code], zone)

        {:ok, updated_state, zone}
    end
  end

  def create_zone(_state, _code, _name, _impact_level, _estimated_people) do
    {:error, :invalid_arguments}
  end

  # --------------------------------------------------
  # Registro de sectores
  # --------------------------------------------------

  @doc """
  Agrega un sector a una zona existente.

  ## Parámetros
  - `state`: estado general del sistema.
  - `zone_code`: código de la zona a la que pertenece.
  - `sector_code`: código único del sector dentro de la zona.
  - `name`: nombre del sector.
  - `affected_people`: cantidad de personas afectadas.

  ## Retorna
  - `{:ok, updated_state, sector}` si el registro es exitoso.
  - `{:error, reason}` si ocurre una validación incorrecta.

  ## Posibles errores
  - `:invalid_arguments`: argumentos inválidos.
  - `:zone_not_found`: la zona no existe.
  - `:empty_fields`: código o nombre vacío.
  - `:sector_already_exists`: el sector ya existe en esa zona.
  - `:invalid_people_count`: cantidad de personas inválida.

  ## Ejemplo
      add_sector(state, "Z001", "S001", "Sector Norte", 100)
  """
  def add_sector(state, zone_code, sector_code, name, affected_people)
      when is_map(state) and is_binary(zone_code) and
             is_binary(sector_code) and is_binary(name) do
    cond do
      String.trim(sector_code) == "" or String.trim(name) == "" ->
        {:error, :empty_fields}

      not (is_integer(affected_people) and affected_people >= 0) ->
        {:error, :invalid_people_count}

      true ->
        case Map.fetch(state.zones, zone_code) do
          {:ok, zone} ->
            if Map.has_key?(zone.sectors, sector_code) do
              {:error, :sector_already_exists}
            else
              sector = Data.new_sector(sector_code, name, affected_people)

              updated_state =
                put_in(state.zones[zone_code].sectors[sector_code], sector)

              {:ok, updated_state, sector}
            end

          :error ->
            {:error, :zone_not_found}
        end
    end
  end

  def add_sector(_state, _zone_code, _sector_code, _name, _affected_people) do
    {:error, :invalid_arguments}
  end

  # --------------------------------------------------
  # Registro de puntos de atención
  # --------------------------------------------------

  @doc """
  Agrega un punto de atención a un sector existente.

  ## Parámetros
  - `state`: estado general del sistema.
  - `zone_code`: código de la zona.
  - `sector_code`: código del sector.
  - `point_code`: código del punto de atención.
  - `name`: nombre del punto.
  - `description`: descripción del punto.

  ## Retorna
  - `{:ok, updated_state, point}` si el registro es exitoso.
  - `{:error, reason}` si ocurre una validación incorrecta.

  ## Posibles errores
  - `:invalid_arguments`: argumentos inválidos.
  - `:zone_not_found`: la zona no existe.
  - `:sector_not_found`: el sector no existe.
  - `:empty_fields`: código, nombre o descripción vacío.
  - `:point_already_exists`: el punto ya está registrado.

  ## Ejemplo
      add_attention_point(
        state,
        "Z001",
        "S001",
        "P001",
        "Primeros auxilios",
        "Atención médica básica"
      )
  """
  def add_attention_point(
        state,
        zone_code,
        sector_code,
        point_code,
        name,
        description
      )
      when is_map(state) and is_binary(zone_code) and
             is_binary(sector_code) and is_binary(point_code) and
             is_binary(name) and is_binary(description) do
    cond do
      String.trim(point_code) == "" or
        String.trim(name) == "" or
          String.trim(description) == "" ->
        {:error, :empty_fields}

      true ->
        case Map.fetch(state.zones, zone_code) do
          {:ok, zone} ->
            case Map.fetch(zone.sectors, sector_code) do
              {:ok, sector} ->
                if Map.has_key?(sector.attention_points, point_code) do
                  {:error, :point_already_exists}
                else
                  point =
                    Data.new_attention_point(point_code, name, description)

                  updated_state =
                    put_in(
                      state.zones[zone_code].sectors[sector_code].attention_points[point_code],
                      point
                    )

                  {:ok, updated_state, point}
                end

              :error ->
                {:error, :sector_not_found}
            end

          :error ->
            {:error, :zone_not_found}
        end
    end
  end

  def add_attention_point(
        _state,
        _zone_code,
        _sector_code,
        _point_code,
        _name,
        _description
      ) do
    {:error, :invalid_arguments}
  end

  # --------------------------------------------------
  # Consultas recursivas
  # --------------------------------------------------

  @doc """
  Obtiene todos los puntos de atención registrados en el sistema.

  Recorre recursivamente las zonas, sus sectores y los puntos
  de atención asociados.

  ## Parámetros
  - `state`: estado general del sistema.

  ## Retorna
  - `{:ok, points}` con la lista de puntos encontrados.
  - `{:error, :invalid_arguments}` si el estado es inválido.

  ## Ejemplo
      list_all_attention_points(state)
  """
  def list_all_attention_points(state) when is_map(state) do
    points = collect_zone_points(Map.to_list(state.zones), [])
    {:ok, Enum.reverse(points)}
  end

  def list_all_attention_points(_state) do
    {:error, :invalid_arguments}
  end

  # Recorre recursivamente las zonas.
  defp collect_zone_points([], accumulator), do: accumulator

  defp collect_zone_points([{_zone_code, zone} | remaining], accumulator) do
    updated_accumulator =
      collect_sector_points(
        Map.to_list(zone.sectors),
        zone.code,
        accumulator
      )

    collect_zone_points(remaining, updated_accumulator)
  end

  # Recorre los sectores de cada zona.
  defp collect_sector_points([], _zone_code, accumulator), do: accumulator

  defp collect_sector_points(
         [{_sector_code, sector} | remaining],
         zone_code,
         accumulator
       ) do
    updated_accumulator =
      collect_point_entries(
        Map.to_list(sector.attention_points),
        zone_code,
        sector.code,
        accumulator
      )

    collect_sector_points(remaining, zone_code, updated_accumulator)
  end

  # Recorre los puntos de atención de cada sector.
  defp collect_point_entries(
         [],
         _zone_code,
         _sector_code,
         accumulator
       ),
       do: accumulator

  defp collect_point_entries(
         [{_point_code, point} | remaining],
         zone_code,
         sector_code,
         accumulator
       ) do
    entry = %{
      zone_code: zone_code,
      sector_code: sector_code,
      point: point
    }

    collect_point_entries(
      remaining,
      zone_code,
      sector_code,
      [entry | accumulator]
    )
  end

  @doc """
  Obtiene estadísticas de una zona y sus sectores.

  ## Parámetros
  - `state`: estado general del sistema.
  - `zone_code`: código de la zona que se desea consultar.

  ## Retorna
  - `{:ok, statistics}` con la información acumulada.
  - `{:error, :zone_not_found}` si la zona no existe.
  - `{:error, :invalid_arguments}` si los argumentos son inválidos.

  ## Ejemplo
      zone_statistics(state, "Z001")
  """
  def zone_statistics(state, zone_code)
      when is_map(state) and is_binary(zone_code) do
    case Map.fetch(state.zones, zone_code) do
      {:ok, zone} ->
        {sector_count, affected_people} =
          calculate_sector_statistics(Map.to_list(zone.sectors), 0, 0)

        statistics = %{
          zone: zone,
          sector_count: sector_count,
          affected_people_in_sectors: affected_people
        }

        {:ok, statistics}

      :error ->
        {:error, :zone_not_found}
    end
  end

  def zone_statistics(_state, _zone_code) do
    {:error, :invalid_arguments}
  end

  # Calcula la cantidad de sectores y personas afectadas.
  defp calculate_sector_statistics([], sector_count, affected_people) do
    {sector_count, affected_people}
  end

  defp calculate_sector_statistics(
         [{_sector_code, sector} | remaining],
         sector_count,
         affected_people
       ) do
    calculate_sector_statistics(
      remaining,
      sector_count + 1,
      affected_people + sector.affected_people
    )
  end
end
