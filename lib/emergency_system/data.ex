defmodule EmergencySystem.Data do
  @moduledoc """
  Define las estructuras de datos principales utilizadas por el
  Sistema Distribuido de Coordinación y Gestión de Emergencias.

  El módulo se encarga de inicializar el estado general del sistema
  y proporcionar las estructuras iniciales para las entidades
  que participan en la gestión de emergencias.

  El módulo incluye funciones para:

  - inicializar el estado general del sistema;
  - crear estructuras para las zonas afectadas;
  - crear estructuras para los sectores de cada zona;
  - crear estructuras para los puntos de atención.

  ## Información

  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  # -----------------------------------
  # Inicialización del sistema
  # -----------------------------------

  @doc """
  Inicializa el estado general del sistema de emergencias.

  Crea un mapa que contiene las colecciones necesarias para
  administrar los usuarios, zonas, necesidades, recursos,
  personas afectadas, mascotas y albergues.

  También inicializa las colecciones destinadas al registro
  de usuarios activos y al historial de actividades.

  ## Parámetros

  Esta función no recibe parámetros.

  ## Retorno

  Un mapa con las siguientes claves:

  - `users`: usuarios registrados.
  - `zones`: zonas afectadas.
  - `needs`: necesidades reportadas.
  - `resources`: recursos disponibles.
  - `people`: personas afectadas.
  - `messages`: mensajes registrados.
  - `pets`: reportes de mascotas.
  - `shelters`: albergues registrados.
  - `active_users`: conjunto de usuarios conectados.
  - `activity_log`: historial de actividades.

  ## Ejemplo

      state = EmergencySystem.Data.initial_state()

      state.users
      # %{}

      MapSet.size(state.active_users)
      # 0
  """
  def initial_state do
    %{
      users: %{},
      zones: %{},
      needs: %{},
      resources: %{},
      resource_stocks: %{},
      resource_movements: [],
      resource_assignments: [],
      people: %{},
      person_status_history: [],
      messages: [],
      pets: %{},
      shelters: %{},
      active_users: MapSet.new(),
      activity_log: []
    }
  end

  # -----------------------------------
  # Estructuras de zonas
  # -----------------------------------

  @doc """
  Crea la estructura inicial de una zona afectada.

  Una zona representa un área geográfica impactada por una
  emergencia y puede contener varios sectores.

  ## Parámetros

  - `code`: identificador único de la zona.
  - `name`: nombre de la zona.
  - `impact_level`: nivel de impacto de la emergencia.
  - `estimated_people`: cantidad estimada de personas afectadas.

  ## Retorno

  Un mapa con la información de la zona y una colección vacía
  de sectores.

  ## Ejemplo

      zone = EmergencySystem.Data.new_zone(
        "Z001",
        "Zona Norte",
        :critical,
        200
      )

      zone.name
      # "Zona Norte"
  """
  def new_zone(code, name, impact_level, estimated_people) do
    %{
      code: code,
      name: name,
      impact_level: impact_level,
      estimated_people: estimated_people,
      sectors: %{}
    }
  end

  # -----------------------------------
  # Estructuras de sectores
  # -----------------------------------

  @doc """
  Crea la estructura inicial de un sector perteneciente a una zona.

  Cada sector representa una subdivisión de una zona afectada
  y puede contener diferentes puntos de atención.

  ## Parámetros

  - `code`: identificador del sector.
  - `name`: nombre del sector.
  - `affected_people`: cantidad de personas afectadas en el sector.

  ## Retorno

  Un mapa con la información del sector y una colección vacía
  de puntos de atención.

  ## Ejemplo

      sector = EmergencySystem.Data.new_sector(
        "S001",
        "Sector 1",
        100
      )

      sector.affected_people
      # 100
  """
  def new_sector(code, name, affected_people) do
    %{
      code: code,
      name: name,
      affected_people: affected_people,
      attention_points: %{}
    }
  end

  # -----------------------------------
  # Estructuras de puntos de atención
  # -----------------------------------

  @doc """
  Crea la estructura inicial de un punto de atención.

  Los puntos de atención representan lugares destinados a
  brindar servicios o asistencia a las personas afectadas.

  ## Parámetros

  - `code`: identificador del punto de atención.
  - `name`: nombre del punto de atención.
  - `description`: descripción de los servicios o actividades
    que se realizan en el lugar.

  ## Retorno

  Un mapa con la información del punto de atención.

  ## Ejemplo

      point = EmergencySystem.Data.new_attention_point(
        "P001",
        "Puesto de salud",
        "Atención de primeros auxilios"
      )

      point.name
      # "Puesto de salud"
  """
  def new_attention_point(code, name, description) do
    %{
      code: code,
      name: name,
      description: description
    }
  end
end
