
defmodule EmergencySystem.Supervisor do
  use Supervisor

  @moduledoc """
  Supervisa los procesos principales del sistema de emergencias.

  Inicia y monitorea los servidores encargados del estado compartido,
  las necesidades y los recursos. Permite reiniciar los procesos
  cuando ocurre una falla.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  alias EmergencySystem.Processes.StateServer
  alias EmergencySystem.Processes.NeedServer
  alias EmergencySystem.Processes.ResourceServer

  @doc """
  Inicia el supervisor y sus procesos hijos.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
@impl true
def init(_opts) do
  children = [
    {StateServer, name: StateServer},
    {NeedServer, state_server: StateServer, name: NeedServer},
    {ResourceServer, state_server: StateServer, name: ResourceServer}
  ]

  Supervisor.init(children, strategy: :one_for_one)
end

end
