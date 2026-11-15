defmodule EmergencySystem.Communication.MessageManager do
  @moduledoc """
  Gestiona la comunicación entre personas y familiares durante una emergencia.

  Permite registrar mensajes, consultar los mensajes enviados y actualizar
  su estado de entrega.

  ## Funcionalidades

  - Registrar mensajes entre remitentes y destinatarios.
  - Consultar mensajes asociados a un destinatario.
  - Actualizar el estado de entrega de los mensajes.

  ## Información del módulo

  - Versión: 1.0
  - Autores: Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - Fecha: noviembre de 2026
  - Licencia: GNU GPL v3
  """

  @valid_statuses [:pending, :delivered]

  # ============================================================
  # REGISTRO DE MENSAJES
  # ============================================================

  @doc """
  Registra un mensaje dirigido a una persona o familia.

  ## Parámetros

  - state: estado actual del sistema.
  - id: identificador único del mensaje.
  - sender: remitente del mensaje.
  - recipient: destinatario del mensaje.
  - content: contenido del mensaje.

  ## Retorna

  - `{:ok, updated_state, message}` si el registro es exitoso.
  - `{:error, reason}` si ocurre un error de validación.
  """
  def register_message(state, id, sender, recipient, content) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(id) || {:error, :invalid_id},
         true <- valid_text?(sender) || {:error, :invalid_sender},
         true <- valid_text?(recipient) || {:error, :invalid_recipient},
         true <- valid_text?(content) || {:error, :invalid_content},
         true <-
           not message_exists?(state.messages, id) ||
             {:error, :duplicate_message} do
      message = %{
        id: id,
        sender: sender,
        recipient: recipient,
        content: content,
        timestamp: DateTime.utc_now(),
        status: :pending
      }

      updated_state = %{
        state
        | messages: [message | state.messages]
      }

      {:ok, updated_state, message}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # CONSULTA DE MENSAJES
  # ============================================================

  @doc """
  Consulta los mensajes registrados aplicando filtros opcionales.

  ## Parámetros

  - state: estado actual del sistema.
  - filters: mapa con los filtros opcionales:
    - `:sender`: remitente del mensaje.
    - `:recipient`: destinatario del mensaje.
    - `:status`: estado del mensaje.

  ## Retorna

  - `{:ok, messages}` con los mensajes encontrados.
  - `{:error, reason}` si los datos son inválidos.
  """
  def list_messages(state, filters \\ %{}) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- is_map(filters) || {:error, :invalid_filters},
         true <- valid_filters?(filters) || {:error, :invalid_filters} do
      messages =
        Enum.filter(state.messages, fn message ->
          Enum.all?(filters, fn
            {:sender, sender} ->
              message.sender == sender

            {:recipient, recipient} ->
              message.recipient == recipient

            {:status, status} ->
              message.status == status
          end)
        end)

      {:ok, messages}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_filters}
    end
  end

  # ============================================================
  # ACTUALIZACIÓN DEL ESTADO DE LOS MENSAJES
  # ============================================================

  @doc """
  Actualiza el estado de entrega de un mensaje.

  ## Parámetros

  - state: estado actual del sistema.
  - message_id: identificador del mensaje.
  - new_status: nuevo estado (:pending o :delivered).

  ## Retorna

  - `{:ok, updated_state, updated_message}` si la actualización es exitosa.
  - `{:error, reason}` si ocurre un error.
  """
  def update_message_status(state, message_id, new_status) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_text?(message_id) || {:error, :invalid_id},
         true <- new_status in @valid_statuses || {:error, :invalid_status},
         {:ok, message} <- find_message(state.messages, message_id) do
      updated_message = %{message | status: new_status}

      updated_messages =
        Enum.map(state.messages, fn current_message ->
          if current_message.id == message_id do
            updated_message
          else
            current_message
          end
        end)

      updated_state = %{state | messages: updated_messages}

      {:ok, updated_state, updated_message}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp valid_state?(state) when is_map(state) do
    is_list(Map.get(state, :messages))
  end

  defp valid_state?(_state), do: false

  defp valid_text?(value) do
    is_binary(value) and String.trim(value) != ""
  end

  defp message_exists?(messages, id) do
    Enum.any?(messages, fn message ->
      message.id == id
    end)
  end

  defp valid_filters?(filters) do
    allowed_keys = [:sender, :recipient, :status]

    Enum.all?(filters, fn
      {key, value} when key in [:sender, :recipient] ->
        key in allowed_keys and valid_text?(value)

      {:status, status} ->
        status in @valid_statuses

      _ ->
        false
    end)
  end

  defp find_message(messages, message_id) do
    case Enum.find(messages, fn message ->
           message.id == message_id
         end) do
      nil -> {:error, :message_not_found}
      message -> {:ok, message}
    end
  end
end
