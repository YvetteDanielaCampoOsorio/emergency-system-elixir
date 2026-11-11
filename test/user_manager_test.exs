
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
end
