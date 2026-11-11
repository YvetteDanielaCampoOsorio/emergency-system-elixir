defmodule EmergencySystem.Data do
  @moduledoc """
  Define las estructuras de datos principales
  utilizadas por el sistema de emergencias.
  """

  @doc """
  Inicializa el estado general del sistema.
  """
  def initial_state do
    %{
      users: %{},
      zones: %{},
      needs: %{},
      resources: %{},
      people: %{},
      messages: [],
      pets: %{},
      shelters: %{},
      active_users: MapSet.new(),
      activity_log: []
    }
  end

  @doc """
  Crea la estructura inicial de una zona.
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

  @doc """
  Crea la estructura inicial de un sector.
  """
  def new_sector(code, name, affected_people) do
    %{
      code: code,
      name: name,
      affected_people: affected_people,
      attention_points: %{}
    }
  end

  @doc """
  Crea la estructura inicial de un punto de atención.
  """
  def new_attention_point(code, name, description) do
    %{
      code: code,
      name: name,
      description: description
    }
  end
end
