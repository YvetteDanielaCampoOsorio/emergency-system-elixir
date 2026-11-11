defmodule EmergencySystem.Users.UserManager do
  @moduledoc """
  Gestiona el registro, autenticación y conexión de los usuarios
  que participan en el Sistema de Gestión de Emergencias.

  El módulo incluye funciones para:

  - conectar usuarios existentes;
  - registrar automáticamente usuarios nuevos;
  - verificar credenciales;
  - desconectar usuarios;
  - consultar información de usuarios;
  - registrar actividades realizadas por los usuarios.

  ## Información

  - **Versión:** 1.0
  - **Autor:** Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - **Fecha:** noviembre de 2026
  - **Licencia:** GNU GPL v3
  """

  @valid_roles [:citizen, :volunteer, :coordinator, :administrator]

  @permissions %{
    view_information: [:citizen, :volunteer, :coordinator, :administrator],
    register_need: [:citizen, :volunteer, :coordinator, :administrator],
    assign_resource: [:coordinator, :administrator],
    manage_zones: [:coordinator, :administrator],
    manage_users: [:administrator]
  }

  # -----------------------------------
  # Conexión y registro de usuarios
  # -----------------------------------

  @doc """
  Conecta un usuario al sistema.

  Si el usuario no existe, lo registra utilizando los datos
  proporcionados. Si ya existe, verifica su contraseña.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `username`: nombre de usuario.
  - `password`: contraseña proporcionada.
  - `user_data`: mapa con nombre completo, rol y zona principal.

  El mapa `user_data` debe contener las claves:
  `:full_name`, `:role` y `:zone`.

  ## Retorno

  - `{:ok, updated_state, user}` si la conexión es exitosa.
  - `{:error, reason}` si ocurre un error.

  ## Posibles errores

  - `:already_connected`: el usuario ya tiene una sesión activa.
  - `:invalid_password`: la contraseña no coincide con la registrada.
  - `:empty_credentials`: el nombre de usuario o la contraseña
    están vacíos al registrar un usuario.
  - `:invalid_full_name`: el nombre completo no es válido.
  - `:invalid_role`: el rol no pertenece a los roles permitidos.
  - `:invalid_zone`: la zona no es válida.
  - `:invalid_arguments`: los argumentos no tienen los tipos esperados.

  ## Ejemplo

      user_data = %{
        full_name: "Laura Gómez",
        role: :coordinator,
        zone: "centro"
      }

      EmergencySystem.Users.UserManager.connect(
        state,
        "laura",
        "1234",
        user_data
      )
  """
  def connect(state, username, password, user_data)
      when is_map(state) and is_binary(username) and
             is_binary(password) and is_map(user_data) do
    case Map.fetch(state.users, username) do
      {:ok, user} ->
        cond do
          MapSet.member?(state.active_users, username) ->
            {:error, :already_connected}

          verify_password(password, user) ->
            updated_state = activate_user(state, username, :login)
            {:ok, updated_state, public_user(user)}

          true ->
            {:error, :invalid_password}
        end

      :error ->
        register_and_connect(state, username, password, user_data)
    end
  end

  def connect(_state, _username, _password, _user_data) do
    {:error, :invalid_arguments}
  end

  # -----------------------------------
  # Desconexión de usuarios
  # -----------------------------------

  @doc """
  Desconecta un usuario del sistema de gestión de emergencias.

  Verifica que el usuario esté registrado y tenga una sesión
  activa. Si cumple ambas condiciones, elimina su nombre del
  conjunto de usuarios activos y registra la desconexión.

  ## Parámetros

  - `state`: mapa que contiene el estado actual del sistema.
  - `username`: nombre de usuario que desea desconectarse.

  ## Valor de retorno

  - `{:ok, updated_state, user}`: cuando la desconexión se realiza
    correctamente. Contiene el estado actualizado y los datos
    públicos del usuario.
  - `{:error, reason}`: cuando no es posible realizar la operación.

  ## Posibles errores

  - `:user_not_found`: el usuario no está registrado.
  - `:not_connected`: el usuario no tiene una sesión activa.
  - `:invalid_arguments`: los argumentos no tienen los tipos esperados.

  ## Ejemplo de uso

      EmergencySystem.Users.UserManager.disconnect(state, "laura")
  """
  def disconnect(state, username)
      when is_map(state) and is_binary(username) do
    case Map.fetch(state.users, username) do
      {:ok, user} ->
        if MapSet.member?(state.active_users, username) do
          updated_state =
            state
            |> update_in(
              [:active_users],
              &MapSet.delete(&1, username)
            )
            |> record_activity(username, :logout)

          {:ok, updated_state, public_user(user)}
        else
          {:error, :not_connected}
        end

      :error ->
        {:error, :user_not_found}
    end
  end

  def disconnect(_state, _username) do
    {:error, :invalid_arguments}
  end

  # -----------------------------------
  # Autorización según el rol
  # -----------------------------------

  @doc """
  Verifica si un usuario tiene autorización para realizar una operación.

  Comprueba que el usuario esté registrado, tenga una sesión activa
  y que su rol esté autorizado para ejecutar la acción solicitada.

  ## Parámetros

  - `state`: mapa que contiene el estado actual del sistema.
  - `username`: nombre de usuario que solicita realizar la operación.
  - `action`: átomo que identifica la operación que desea ejecutar.

  ## Valor de retorno

  - `{:ok, user}`: cuando el usuario está autorizado. Contiene sus datos públicos.
  - `{:error, reason}`: cuando no puede realizar la operación.

  ## Posibles errores

  - `:user_not_found`: el usuario no está registrado.
  - `:not_connected`: el usuario no tiene una sesión activa.
  - `:invalid_action`: la operación no está definida en el mapa de permisos.
  - `:unauthorized`: el rol del usuario no tiene permiso para realizar la operación.
  - `:invalid_arguments`: los argumentos no tienen los tipos esperados.

  ## Ejemplo de uso

      EmergencySystem.Users.UserManager.authorize(
        state,
        "laura",
        :assign_resource
      )
  """
  def authorize(state, username, action)
      when is_map(state) and is_binary(username) and is_atom(action) do
    case Map.fetch(state.users, username) do
      {:ok, user} ->
        if MapSet.member?(state.active_users, username) do
          case Map.fetch(@permissions, action) do
            {:ok, allowed_roles} ->
              if Enum.member?(allowed_roles, user.role) do
                {:ok, public_user(user)}
              else
                {:error, :unauthorized}
              end

            :error ->
              {:error, :invalid_action}
          end
        else
          {:error, :not_connected}
        end

      :error ->
        {:error, :user_not_found}
    end
  end

  def authorize(_state, _username, _action) do
    {:error, :invalid_arguments}
  end

  # -----------------------------------
  # Registro automático
  # -----------------------------------

  # Registra un usuario nuevo con los datos proporcionados,
  # genera sus credenciales de autenticación y establece su sesión activa.
  defp register_and_connect(state, username, password, user_data) do
    full_name = Map.get(user_data, :full_name)
    role = Map.get(user_data, :role)
    zone = Map.get(user_data, :zone)

    cond do
      username == "" or password == "" ->
        {:error, :empty_credentials}

      not is_binary(full_name) or full_name == "" ->
        {:error, :invalid_full_name}

      role not in @valid_roles ->
        {:error, :invalid_role}

      not is_binary(zone) or zone == "" ->
        {:error, :invalid_zone}

      true ->
        salt = :crypto.strong_rand_bytes(16)

        user = %{
          username: username,
          full_name: full_name,
          password_salt: salt,
          password_hash: hash_password(password, salt),
          role: role,
          zone: zone
        }

        updated_state =
          state
          |> put_in([:users, username], user)
          |> activate_user(username, :registration)

        {:ok, updated_state, public_user(user)}
    end
  end

  # -----------------------------------
  # Verificación de credenciales
  # -----------------------------------

  # Verifica si la contraseña ingresada corresponde a las credenciales
  # almacenadas para el usuario, utilizando su sal y hash registrados.
  defp verify_password(password, user) do
    hash_password(password, user.password_salt) ==
      user.password_hash
  end

  # Genera un hash seguro de la contraseña mediante PBKDF2-HMAC
  # con SHA-256, utilizando una sal y 100.000 iteraciones.
  defp hash_password(password, salt) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, 100_000, 32)
  end

  # -----------------------------------
  # Administración de sesiones
  # -----------------------------------

  # Agrega al usuario al conjunto de sesiones activas y registra
  # la actividad realizada (registro o inicio de sesión).
  defp activate_user(state, username, action) do
    state
    |> update_in([:active_users], &MapSet.put(&1, username))
    |> record_activity(username, action)
  end

  # Registra una actividad del usuario en el historial del sistema,
  # almacenando su nombre de usuario, acción y fecha de ejecución.
  defp record_activity(state, username, action) do
    activity = %{
      username: username,
      action: action,
      timestamp: DateTime.utc_now()
    }

    update_in(state.activity_log, &[activity | &1])
  end

  # -----------------------------------
  # Protección de información
  # -----------------------------------

  # Genera una versión pública de los datos del usuario,
  # excluyendo la sal y el hash de la contraseña para proteger
  # la información utilizada durante la autenticación.
  defp public_user(user) do
    Map.drop(user, [:password_salt, :password_hash])
  end
end
