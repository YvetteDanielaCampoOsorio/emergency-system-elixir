defmodule EmergencySystem.Persistence.Storage do
  @moduledoc """
  Gestiona la persistencia del sistema de emergencias mediante
  archivos de texto plano.

  Permite guardar y recuperar el estado general del sistema,
  conservando sus estructuras y tipos de datos.

  Versión: 1.0
  Autores: Yvette Daniela Campo Osorio,
           Sofia Aviles Diaz,
           Santiago Barrero Lopez
  Fecha: noviembre de 2026
  Licencia: GNU GPL v3
  """

  @file_header "EMERGENCY_SYSTEM_V1\n"

  # ============================================================
  # GUARDADO DE INFORMACIÓN
  # ============================================================

  @doc """
  Guarda el estado del sistema en un archivo de texto.

  ## Parámetros

  - state: mapa con el estado general del sistema.
  - path: ruta del archivo donde se guardará la información.

  ## Retorna

  - :ok si el archivo se guarda correctamente.
  - {:error, reason} si los datos o la escritura son inválidos.
  """
  def save(state, path) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_path?(path) || {:error, :invalid_path} do
      encoded_state =
        state
        |> :erlang.term_to_binary()
        |> Base.encode64()

      content = @file_header <> encoded_state

      case File.write(path, content) do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  end

  # ============================================================
  # RECUPERACIÓN DE INFORMACIÓN
  # ============================================================

  @doc """
  Recupera el estado del sistema desde un archivo de texto.

  ## Parámetros

  - path: ruta del archivo que contiene la información.

  ## Retorna

  - {:ok, state} si la información se recupera correctamente.
  - {:error, reason} si el archivo no existe o está dañado.
  """
  def load(path) do
    with true <- valid_path?(path) || {:error, :invalid_path},
         {:ok, content} <- File.read(path),
         true <-
           String.starts_with?(content, @file_header) ||
             {:error, :invalid_file_format},
         encoded_state <-
           String.replace_prefix(content, @file_header, ""),
         {:ok, binary_state} <- decode_content(encoded_state),
         state <- :erlang.binary_to_term(binary_state, [:safe]),
         true <- valid_state?(state) || {:error, :invalid_state} do
      {:ok, state}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_data}
    end
  rescue
    ArgumentError -> {:error, :corrupted_file}
  end

  # ============================================================
  # CONSULTA DE ARCHIVOS
  # ============================================================

  @doc """
  Comprueba si existe un archivo de persistencia.

  ## Parámetros

  - path: ruta del archivo.

  ## Retorna

  - true si el archivo existe.
  - false si no existe o la ruta no es válida.
  """
  def exists?(path) do
    valid_path?(path) and File.regular?(path)
  end

  # ============================================================
  # VALIDACIONES
  # ============================================================

  @doc false
  defp valid_state?(state) do
    is_map(state) and
      Enum.all?(
        [
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
        ],
        &Map.has_key?(state, &1)
      )
  end

  @doc false
  defp valid_path?(path) do
    is_binary(path) and String.trim(path) != ""
  end

  # ============================================================
  # DECODIFICACIÓN
  # ============================================================

  @doc false
  defp decode_content(encoded_state) do
    case Base.decode64(encoded_state) do
      {:ok, binary_state} -> {:ok, binary_state}
      :error -> {:error, :corrupted_file}
    end
  end
end
