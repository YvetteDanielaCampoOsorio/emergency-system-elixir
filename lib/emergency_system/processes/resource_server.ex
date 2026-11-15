defmodule EmergencySystem.Processes.ResourceServer do
  use GenServer

  @moduledoc """
  Administra las solicitudes relacionadas con los recursos
  de emergencia mediante un proceso independiente.

  Recibe mensajes de los usuarios y delega las operaciones
  al ResourceManager mediante el StateServer.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  alias EmergencySystem.Processes.StateServer
  alias EmergencySystem.Resources.ResourceManager

  # ============================================================
  # INICIO DEL SERVIDOR
  # ============================================================

  @doc """
  Inicia el proceso encargado de gestionar los recursos.

  ## Opciones

  - :state_server permite indicar el proceso que administra
    el estado compartido.
  - :name permite registrar el proceso con un nombre.
  """
  def start_link(opts \\ []) do
    state_server = Keyword.get(opts, :state_server, StateServer)
    server_opts = Keyword.drop(opts, [:state_server])

    GenServer.start_link(__MODULE__, state_server, server_opts)
  end

  # ============================================================
  # REGISTRO DE RECURSOS
  # ============================================================

  @doc """
  Envía una solicitud para registrar un recurso.
  """
  def register_resource(
        server \\ __MODULE__,
        code,
        name,
        category,
        quantity,
        unit,
        location,
        description
      ) do
    GenServer.call(
      server,
      {:register_resource, code, name, category, quantity, unit, location, description}
    )
  end

  # ============================================================
  # CONSULTA DE RECURSOS
  # ============================================================

  @doc """
  Solicita la lista de recursos registrados.
  """
  def list_resources(server \\ __MODULE__) do
    GenServer.call(server, :list_resources)
  end

  @doc """
  Filtra los recursos por categoría.
  """
  def filter_by_category(server \\ __MODULE__, category) do
    GenServer.call(server, {:filter_by_category, category})
  end

  @doc """
  Filtra los recursos por ubicación.
  """
  def filter_by_location(server \\ __MODULE__, location) do
    GenServer.call(server, {:filter_by_location, location})
  end

  @doc """
  Consulta el historial de movimientos de inventario.
  """
  def list_resource_movements(server \\ __MODULE__) do
    GenServer.call(server, :list_resource_movements)
  end

  # ============================================================
  # MOVIMIENTOS DE INVENTARIO
  # ============================================================

  @doc """
  Registra una entrada de inventario.
  """
  def register_entry(server \\ __MODULE__, resource_code, location, quantity) do
    GenServer.call(
      server,
      {:register_entry, resource_code, location, quantity}
    )
  end

  @doc """
  Registra una salida de inventario.
  """
  def register_exit(server \\ __MODULE__, resource_code, location, quantity) do
    GenServer.call(
      server,
      {:register_exit, resource_code, location, quantity}
    )
  end

  @doc """
  Transfiere recursos entre dos ubicaciones.
  """
  def transfer_resource(
        server \\ __MODULE__,
        resource_code,
        origin,
        destination,
        quantity
      ) do
    GenServer.call(
      server,
      {:transfer_resource, resource_code, origin, destination, quantity}
    )
  end

  # ============================================================
  # RECEPCIÓN Y PROCESAMIENTO DE MENSAJES
  # ============================================================

  @impl true
  def init(state_server) do
    {:ok, state_server}
  end

  @impl true
  def handle_call(
        {:register_resource, code, name, category, quantity, unit, location, description},
        _from,
        state_server
      ) do
    result =
      StateServer.transact(state_server, fn state ->
        ResourceManager.register_resource(
          state,
          code,
          name,
          category,
          quantity,
          unit,
          location,
          description
        )
      end)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call(:list_resources, _from, state_server) do
    state = StateServer.get_state(state_server)
    result = ResourceManager.list_resources(state)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:filter_by_category, category}, _from, state_server) do
    state = StateServer.get_state(state_server)
    result = ResourceManager.filter_by_category(state, category)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:filter_by_location, location}, _from, state_server) do
    state = StateServer.get_state(state_server)
    result = ResourceManager.filter_by_location(state, location)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call(:list_resource_movements, _from, state_server) do
    state = StateServer.get_state(state_server)
    result = ResourceManager.list_resource_movements(state)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:register_entry, resource_code, location, quantity}, _from, state_server) do
    result =
      StateServer.transact(state_server, fn state ->
        ResourceManager.register_entry(state, resource_code, location, quantity)
      end)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:register_exit, resource_code, location, quantity}, _from, state_server) do
    result =
      StateServer.transact(state_server, fn state ->
        ResourceManager.register_exit(state, resource_code, location, quantity)
      end)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call(
        {:transfer_resource, resource_code, origin, destination, quantity},
        _from,
        state_server
      ) do
    result =
      StateServer.transact(state_server, fn state ->
        ResourceManager.transfer_resource(
          state,
          resource_code,
          origin,
          destination,
          quantity
        )
      end)

    {:reply, result, state_server}
  end
end
