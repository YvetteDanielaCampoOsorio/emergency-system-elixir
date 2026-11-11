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
end
