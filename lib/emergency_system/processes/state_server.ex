
defmodule EmergencySystem.Processes.StateServer do
  use GenServer

  @moduledoc """
  Administra el estado compartido del sistema de emergencias
  mediante un proceso GenServer.

  Centraliza las consultas y modificaciones del estado para
  evitar que diferentes procesos trabajen sobre copias independientes.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  alias EmergencySystem.Data

  # ============================================================
  # INICIO DEL SERVIDOR
  # ============================================================

  @doc """
  Inicia el servidor con el estado inicial del sistema.

  ## Opciones

  - :initial_state permite proporcionar un estado inicial personalizado.
  - :name permite registrar el proceso con un nombre.

  ## Retorna

  - {:ok, pid} si el servidor inicia correctamente.
  - {:error, reason} si no puede iniciarse.
  """
  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, Data.initial_state())
    server_opts = Keyword.drop(opts, [:initial_state])

    GenServer.start_link(__MODULE__, initial_state, server_opts)
  end

  # ============================================================
  # CONSULTA DEL ESTADO
  # ============================================================

  @doc """
  Obtiene el estado actual del sistema.

  ## Parámetros

  - server: proceso o nombre del servidor.

  ## Retorna

  El mapa con el estado actual del sistema.
  """
  def get_state(server \\ __MODULE__) do
    GenServer.call(server, :get_state)
  end

  # ============================================================
  # MODIFICACIÓN DEL ESTADO
  # ============================================================

  @doc """
  Ejecuta una operación sobre el estado compartido.

  La operación recibe el estado actual y debe retornar:

  - {:ok, updated_state, result} si la modificación es válida.
  - {:error, reason} si la operación no puede realizarse.

  El GenServer procesa las operaciones una por una,
  evitando modificaciones simultáneas sobre el mismo estado.

  ## Parámetros

  - server: proceso o nombre del servidor.
  - operation: función que recibe el estado actual.

  ## Retorna

  - {:ok, result} si la operación se ejecuta correctamente.
  - {:error, reason} si ocurre un error.
  """

  def transact(server \\ __MODULE__, operation)

  def transact(server, operation)
      when is_function(operation, 1) do
    GenServer.call(server, {:transact, operation})
  end

  def transact(_server, _operation) do
    {:error, :invalid_operation}
  end

  # ============================================================
  # CALLBACKS DE GEN_SERVER
  # ============================================================

  @impl true
  def init(initial_state) do
    if valid_state?(initial_state) do
      {:ok, initial_state}
    else
      {:stop, :invalid_initial_state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:transact, operation}, _from, state) do
    try do
      case operation.(state) do
        {:ok, updated_state, result} ->
          if valid_state?(updated_state) do
            {:reply, {:ok, result}, updated_state}
          else
            {:reply, {:error, :invalid_state}, state}
          end

        {:error, reason} ->
          {:reply, {:error, reason}, state}

        _ ->
          {:reply, {:error, :invalid_operation_result}, state}
      end
    rescue
      _ -> {:reply, {:error, :operation_failed}, state}
    end
  end

  # ============================================================
  # VALIDACIONES
  # ============================================================

  defp valid_state?(state) when is_map(state) do
    required_keys = [
      :users,
      :zones,
      :needs,
      :resources,
      :resource_stocks,
      :resource_movements,
      :resource_assignments,
      :people,
      :person_status_history,
      :messages,
      :pets,
      :shelters,
      :active_users,
      :activity_log
    ]

    Enum.all?(required_keys, &Map.has_key?(state, &1))
  end

  defp valid_state?(_state), do: false
end
