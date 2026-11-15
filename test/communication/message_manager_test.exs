defmodule EmergencySystem.Communication.MessageManagerTest do
  use ExUnit.Case

  alias EmergencySystem.Communication.MessageManager

  # ============================================================
  # REGISTRO DE MENSAJES
  # ============================================================

  test "registers a message successfully" do
    state = %{messages: []}

    assert {:ok, updated_state, message} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "Andres",
               "Estoy bien"
             )

    assert message.id == "MSG001"
    assert message.sender == "Laura"
    assert message.recipient == "Andres"
    assert message.content == "Estoy bien"
    assert message.status == :pending
    assert %DateTime{} = message.timestamp
    assert length(updated_state.messages) == 1
  end

  test "rejects an empty message identifier" do
    state = %{messages: []}

    assert {:error, :invalid_id} =
             MessageManager.register_message(
               state,
               "",
               "Laura",
               "Andres",
               "Estoy bien"
             )
  end

  test "rejects an empty sender" do
    state = %{messages: []}

    assert {:error, :invalid_sender} =
             MessageManager.register_message(
               state,
               "MSG001",
               "",
               "Andres",
               "Estoy bien"
             )
  end

  test "rejects an empty recipient" do
    state = %{messages: []}

    assert {:error, :invalid_recipient} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "",
               "Estoy bien"
             )
  end

  test "rejects an empty message content" do
    state = %{messages: []}

    assert {:error, :invalid_content} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "Andres",
               ""
             )
  end

  test "rejects duplicate message identifiers" do
    state = %{
      messages: [
        %{id: "MSG001"}
      ]
    }

    assert {:error, :duplicate_message} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "Andres",
               "Estoy bien"
             )
  end

  test "rejects an invalid state structure" do
    state = %{messages: %{}}

    assert {:error, :invalid_state} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "Andres",
               "Estoy bien"
             )
  end

  test "does not modify the original state" do
    state = %{messages: []}

    assert {:ok, updated_state, _message} =
             MessageManager.register_message(
               state,
               "MSG001",
               "Laura",
               "Andres",
               "Estoy bien"
             )

    assert state.messages == []
    assert length(updated_state.messages) == 1
  end

  # ============================================================
  # CONSULTA DE MENSAJES
  # ============================================================

  test "lists all registered messages" do
    state = %{
      messages: [
        %{
          id: "MSG001",
          sender: "Laura",
          recipient: "Andres",
          content: "Estoy bien",
          status: :pending
        },
        %{
          id: "MSG002",
          sender: "Carlos",
          recipient: "Maria",
          content: "Ya llegué",
          status: :delivered
        }
      ]
    }

    assert {:ok, messages} = MessageManager.list_messages(state)
    assert length(messages) == 2
  end

  test "filters messages by recipient" do
    state = %{
      messages: [
        %{
          id: "MSG001",
          sender: "Laura",
          recipient: "Andres",
          content: "Estoy bien",
          status: :pending
        },
        %{
          id: "MSG002",
          sender: "Carlos",
          recipient: "Maria",
          content: "Ya llegué",
          status: :delivered
        }
      ]
    }

    assert {:ok, messages} =
             MessageManager.list_messages(state, %{recipient: "Andres"})

    assert length(messages) == 1
    assert hd(messages).id == "MSG001"
  end

  test "filters messages by sender" do
    state = %{
      messages: [
        %{
          id: "MSG001",
          sender: "Laura",
          recipient: "Andres",
          content: "Estoy bien",
          status: :pending
        },
        %{
          id: "MSG002",
          sender: "Carlos",
          recipient: "Maria",
          content: "Ya llegué",
          status: :delivered
        }
      ]
    }

    assert {:ok, messages} =
             MessageManager.list_messages(state, %{sender: "Carlos"})

    assert length(messages) == 1
    assert hd(messages).id == "MSG002"
  end

  test "filters messages by status" do
    state = %{
      messages: [
        %{
          id: "MSG001",
          sender: "Laura",
          recipient: "Andres",
          content: "Estoy bien",
          status: :pending
        },
        %{
          id: "MSG002",
          sender: "Carlos",
          recipient: "Maria",
          content: "Ya llegué",
          status: :delivered
        }
      ]
    }

    assert {:ok, messages} =
             MessageManager.list_messages(state, %{status: :delivered})

    assert length(messages) == 1
    assert hd(messages).id == "MSG002"
  end

  test "rejects an invalid message filter" do
    state = %{messages: []}

    assert {:error, :invalid_filters} =
             MessageManager.list_messages(state, %{unknown: "value"})
  end

  test "rejects an invalid message status filter" do
    state = %{messages: []}

    assert {:error, :invalid_filters} =
             MessageManager.list_messages(state, %{status: :unknown})
  end

  # ============================================================
  # ACTUALIZACIÓN DEL ESTADO DE LOS MENSAJES
  # ============================================================

  test "updates a pending message to delivered" do
    message = %{
      id: "MSG010",
      sender: "Laura",
      recipient: "Andres",
      content: "Estoy bien",
      status: :pending
    }

    state = %{messages: [message]}

    assert {:ok, updated_state, updated_message} =
             MessageManager.update_message_status(
               state,
               "MSG010",
               :delivered
             )

    assert updated_message.status == :delivered
    assert hd(updated_state.messages).status == :delivered
  end

  test "updates a delivered message to pending" do
    message = %{
      id: "MSG011",
      sender: "Laura",
      recipient: "Andres",
      content: "Estoy bien",
      status: :delivered
    }

    state = %{messages: [message]}

    assert {:ok, _updated_state, updated_message} =
             MessageManager.update_message_status(
               state,
               "MSG011",
               :pending
             )

    assert updated_message.status == :pending
  end

  test "rejects an invalid status when updating a message" do
    state = %{messages: []}

    assert {:error, :invalid_status} =
             MessageManager.update_message_status(
               state,
               "MSG010",
               :unknown
             )
  end

  test "rejects an empty message identifier when updating status" do
    state = %{messages: []}

    assert {:error, :invalid_id} =
             MessageManager.update_message_status(
               state,
               "",
               :delivered
             )
  end

  test "returns an error when the message does not exist" do
    state = %{messages: []}

    assert {:error, :message_not_found} =
             MessageManager.update_message_status(
               state,
               "MSG999",
               :delivered
             )
  end

  test "does not modify the original state when updating a message" do
    message = %{
      id: "MSG012",
      sender: "Laura",
      recipient: "Andres",
      content: "Estoy bien",
      status: :pending
    }

    state = %{messages: [message]}

    assert {:ok, updated_state, _updated_message} =
             MessageManager.update_message_status(
               state,
               "MSG012",
               :delivered
             )

    assert hd(state.messages).status == :pending
    assert hd(updated_state.messages).status == :delivered
  end
end
