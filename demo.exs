alias EmergencySystem.Supervisor
alias EmergencySystem.Processes.StateServer
alias EmergencySystem.Processes.NeedServer
alias EmergencySystem.Processes.ResourceServer
alias EmergencySystem.Zones.ZoneManager
alias EmergencySystem.Users.UserManager
alias EmergencySystem.Assignments.AssignmentManager

IO.puts("\n========================================")
IO.puts(" SISTEMA DE GESTION DE EMERGENCIAS")
IO.puts("========================================")

# Iniciar el arbol de supervision OTP
supervisor_pid = Process.whereis(Supervisor)

IO.puts("\n[OK] Supervisor iniciado correctamente.")
IO.inspect(Elixir.Supervisor.which_children(supervisor_pid),
  label: "Procesos hijos activos"
)

IO.puts("\n[OK] Estado inicial del sistema:")
IO.inspect(StateServer.get_state())

IO.puts("\n[DEMO] Registrando una zona...")

IO.inspect(
  StateServer.transact(StateServer, fn state ->
    ZoneManager.create_zone(state, "Z001", "Zona Norte", :high, 100)
  end),
  label: "Resultado del registro de zona"
)
IO.puts("\n[DEMO] Registrando usuario coordinador...")

IO.inspect(
  StateServer.transact(StateServer, fn state ->
    UserManager.connect(
      state,
      "coordinador",
      "1234",
      %{
        full_name: "Coordinador de Emergencias",
        role: :coordinator,
        zone: "Z001"
      }
    )
  end),
  label: "Resultado del registro del usuario"
)

IO.puts("\n[DEMO] Registrando una necesidad...")

IO.inspect(
  NeedServer.register_need(
    NeedServer,
    "N001",
    "water",
    "Agua potable para familias afectadas",
    100,
    "Z001",
    :critical,
    "coordinador"
  ),
  label: "Resultado del registro"
)

IO.puts("\n[DEMO] Registrando recurso...")

IO.inspect(
  ResourceServer.register_resource(
    ResourceServer,
    "R001",
    "Agua potable",
    :water,
    150,
    "litros",
    "Centro de acopio Norte",
    "Reserva de agua para emergencias"
  ),
  label: "Resultado del registro del recurso"
)

IO.puts("\n[DEMO] Asignando recursos a la necesidad...")

IO.inspect(
  StateServer.transact(StateServer, fn state ->
    AssignmentManager.assign_resource(
      state,
      "N001",
      "R001",
      "Centro de acopio Norte",
      100
    )
  end),
  label: "Resultado de la asignación"
)
IO.puts("\n[DEMO] Consultando inventario actualizado...")

IO.inspect(
  ResourceServer.filter_by_location(
    ResourceServer,
    "Centro de acopio Norte"
  ),
  label: "Recursos disponibles"
)

IO.puts("\n[DEMO] Consultando necesidades...")

IO.inspect(
  NeedServer.list_needs(NeedServer),
  label: "Necesidades registradas"
)

IO.puts("\n[DEMO] Probando asignación con inventario insuficiente...")

IO.inspect(
  StateServer.transact(StateServer, fn state ->
    AssignmentManager.assign_resource(
      state,
      "N001",
      "R001",
      "Centro de acopio Norte",
      100
    )
  end),
  label: "Resultado de la segunda asignación"
)
