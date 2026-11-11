
defmodule EmergencySystem.Users.UserManagerTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Users.UserManager

  setup do
    user_data = %{
      full_name: "Laura Gómez",
      role: :coordinator,
      zone: "centro"
    }

    %{
      state: Data.initial_state(),
      user_data: user_data
    }
  end

  describe "connect/4" do
    test "registra y conecta un usuario nuevo", context do
      assert {:ok, updated_state, user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      assert Map.has_key?(updated_state.users, "laura")
      assert MapSet.member?(updated_state.active_users, "laura")

      assert user.username == "laura"
      assert user.full_name == "Laura Gómez"
      assert user.role == :coordinator
    end

    test "guarda los datos de autenticación internamente pero no los expone",
         context do
      assert {:ok, updated_state, public_user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      stored_user = updated_state.users["laura"]

      assert is_binary(stored_user.password_salt)
      assert is_binary(stored_user.password_hash)

      refute Map.has_key?(public_user, :password_salt)
      refute Map.has_key?(public_user, :password_hash)
    end

    test "permite conectar nuevamente a un usuario registrado", context do
      assert {:ok, registered_state, _user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      inactive_state = %{
        registered_state
        | active_users: MapSet.new()
      }

      assert {:ok, updated_state, user} =
               UserManager.connect(
                 inactive_state,
                 "laura",
                 "1234",
                 context.user_data
               )

      assert user.username == "laura"
      assert MapSet.member?(updated_state.active_users, "laura")
    end

    test "rechaza una contraseña incorrecta", context do
      assert {:ok, registered_state, _user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      inactive_state = %{
        registered_state
        | active_users: MapSet.new()
      }

      assert {:error, :invalid_password} =
               UserManager.connect(
                 inactive_state,
                 "laura",
                 "incorrecta",
                 context.user_data
               )
    end

    test "rechaza un usuario que ya está conectado", context do
      assert {:ok, registered_state, _user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      assert {:error, :already_connected} =
               UserManager.connect(
                 registered_state,
                 "laura",
                 "1234",
                 context.user_data
               )
    end

    test "rechaza credenciales vacías", context do
      assert {:error, :empty_credentials} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "",
                 context.user_data
               )
    end

    test "rechaza un rol no permitido", context do
      invalid_user_data = %{
        context.user_data
        | role: :supervisor
      }

      assert {:error, :invalid_role} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 invalid_user_data
               )
    end
  end

  describe "disconnect/2" do
    test "desconecta un usuario activo", context do
      assert {:ok, connected_state, _user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      assert {:ok, updated_state, user} =
               UserManager.disconnect(connected_state, "laura")

      refute MapSet.member?(updated_state.active_users, "laura")
      assert user.username == "laura"

      assert hd(updated_state.activity_log).action == :logout
    end

    test "rechaza la desconexión de un usuario inexistente", context do
      assert {:error, :user_not_found} =
               UserManager.disconnect(context.state, "desconocido")
    end

    test "rechaza la desconexión de un usuario inactivo", context do
      assert {:ok, connected_state, _user} =
               UserManager.connect(
                 context.state,
                 "laura",
                 "1234",
                 context.user_data
               )

      inactive_state = %{
        connected_state
        | active_users: MapSet.new()
      }

      assert {:error, :not_connected} =
               UserManager.disconnect(inactive_state, "laura")
    end

    test "rechaza argumentos inválidos", context do
      assert {:error, :invalid_arguments} =
               UserManager.disconnect(context.state, 123)
    end
  end

  describe "authorize/3" do
    test "permite una operación autorizada", context do
      assert {:ok, connected_state, _user} =
              UserManager.connect(
                context.state,
                "laura",
                "1234",
                context.user_data
              )

      assert {:ok, user} =
              UserManager.authorize(
                connected_state,
                "laura",
                :assign_resource
              )

      assert user.role == :coordinator
    end

    test "rechaza una operación no autorizada", context do
      citizen_data = %{context.user_data | role: :citizen}

      assert {:ok, connected_state, _user} =
              UserManager.connect(
                context.state,
                "laura",
                "1234",
                citizen_data
              )

      assert {:error, :unauthorized} =
              UserManager.authorize(
                connected_state,
                "laura",
                :assign_resource
              )
    end

    test "rechaza un usuario inexistente", context do
      assert {:error, :user_not_found} =
              UserManager.authorize(
                context.state,
                "desconocido",
                :assign_resource
              )
    end

    test "rechaza un usuario desconectado", context do
      assert {:ok, connected_state, _user} =
              UserManager.connect(
                context.state,
                "laura",
                "1234",
                context.user_data
              )

      assert {:ok, disconnected_state, _user} =
              UserManager.disconnect(connected_state, "laura")

      assert {:error, :not_connected} =
              UserManager.authorize(
                disconnected_state,
                "laura",
                :assign_resource
              )
    end

    test "rechaza una operación desconocida", context do
      assert {:ok, connected_state, _user} =
              UserManager.connect(
                context.state,
                "laura",
                "1234",
                context.user_data
              )

      assert {:error, :invalid_action} =
              UserManager.authorize(
                connected_state,
                "laura",
                :delete_everything
              )
    end

    test "rechaza argumentos inválidos", context do
      assert {:error, :invalid_arguments} =
              UserManager.authorize(
                context.state,
                123,
                :assign_resource
              )
    end
  end
end
