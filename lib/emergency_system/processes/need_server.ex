defmodule EmergencySystem.Processes.NeedServer do
  use GenServer

  @moduledoc """
  Administra las solicitudes relacionadas con las necesidades
  de emergencia mediante un proceso independiente.

  Recibe mensajes de los usuarios y delega las operaciones
  al StateServer para modificar el estado compartido.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  alias EmergencySystem.Needs.NeedManager
  alias EmergencySystem.Processes.StateServer

  # ============================================================
  # INICIO DEL SERVIDOR
  # ============================================================

  @doc """
  Inicia el proceso encargado de gestionar las necesidades.

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
  # REGISTRO DE NECESIDADES
  # ============================================================

  @doc """
  Envía una solicitud para registrar una necesidad.

  El proceso recibe el mensaje y delega el registro
  al NeedManager mediante el StateServer.
  """
  def register_need(
        server \\ __MODULE__,
        id,
        type,
        description,
        quantity,
        zone_code,
        priority,
        reporter
      ) do
    GenServer.call(
      server,
      {:register_need, id, type, description, quantity, zone_code, priority, reporter}
    )
  end

  # ============================================================
  # CONSULTA DE NECESIDADES
  # ============================================================

  @doc """
  Solicita la lista de necesidades aplicando filtros.
  """
  def list_needs(server \\ __MODULE__, filters \\ %{}) do
    GenServer.call(server, {:list_needs, filters})
  end

  # ============================================================
  # ACTUALIZACIÓN DE ESTADOS
  # ============================================================

  @doc """
  Envía una solicitud para cambiar el estado de una necesidad.
  """
  def update_need_status(server \\ __MODULE__, need_id, new_status) do
    GenServer.call(server, {:update_need_status, need_id, new_status})
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
        {:register_need, id, type, description, quantity, zone_code, priority, reporter},
        _from,
        state_server
      ) do
    result =
      StateServer.transact(state_server, fn state ->
        NeedManager.register_need(
          state,
          id,
          type,
          description,
          quantity,
          zone_code,
          priority,
          reporter
        )
      end)

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:list_needs, filters}, _from, state_server) do
    state = StateServer.get_state(state_server)

    result =
      case NeedManager.list_needs(state) do
        {:ok, needs} ->
          apply_need_filters(needs, filters)

        error ->
          error
      end

    {:reply, result, state_server}
  end

  @impl true
  def handle_call({:update_need_status, need_id, new_status}, _from, state_server) do
    result =
      StateServer.transact(state_server, fn state ->
        NeedManager.update_need_status(state, need_id, new_status)
      end)

    {:reply, result, state_server}
  end

  # ============================================================
  # FILTRADO DE NECESIDADES
  # ============================================================

  defp apply_need_filters(needs, filters) when is_map(filters) do
    Enum.reduce(filters, needs, fn
      {:zone_code, value}, acc ->
        Enum.filter(acc, &(&1.zone_code == value))

      {:type, value}, acc ->
        Enum.filter(acc, &(&1.type == value))

      {:priority, value}, acc ->
        Enum.filter(acc, &(&1.priority == value))

      {:status, value}, acc ->
        Enum.filter(acc, &(&1.status == value))

      _filter, acc ->
        acc
    end)
    |> then(&{:ok, &1})
  end

  defp apply_need_filters(_needs, _filters) do
    {:error, :invalid_arguments}
  end
end
