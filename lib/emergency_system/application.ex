
defmodule EmergencySystem.Application do
  use Application

  @moduledoc """
  Punto de entrada de la aplicación EmergencySystem.

  Inicia el supervisor principal encargado de mantener
  activos los procesos del sistema de emergencias.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  @impl true
  def start(_type, _args) do
    EmergencySystem.Supervisor.start_link()
  end
end
