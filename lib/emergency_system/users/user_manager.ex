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
  # Registro automático
  # -----------------------------------

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

  defp verify_password(password, user) do
    hash_password(password, user.password_salt) ==
      user.password_hash
  end

  defp hash_password(password, salt) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, 100_000, 32)
  end

  # -----------------------------------
  # Administración de sesiones
  # -----------------------------------

  defp activate_user(state, username, action) do
    state
    |> update_in([:active_users], &MapSet.put(&1, username))
    |> record_activity(username, action)
  end

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

  defp public_user(user) do
    Map.drop(user, [:password_salt, :password_hash])
  end
end
