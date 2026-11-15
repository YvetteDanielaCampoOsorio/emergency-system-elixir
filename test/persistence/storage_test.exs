defmodule EmergencySystem.Persistence.StorageTest do
  use ExUnit.Case, async: true

  alias EmergencySystem.Data
  alias EmergencySystem.Persistence.Storage

  # ============================================================
  # CONFIGURACIÓN DE PRUEBAS
  # ============================================================

  defp temporary_path do
    filename =
      "storage_test_#{System.unique_integer([:positive])}.txt"

    Path.join(System.tmp_dir!(), filename)
  end

  defp sample_state do
    state = Data.initial_state()

    Map.merge(state, %{
      resource_stocks: %{
        {"R001", "centro_norte"} => 100
      },
      active_users: MapSet.new(["usuario1", "usuario2"]),
      activity_log: [
        %{
          action: :register_resource,
          timestamp: DateTime.utc_now()
        }
      ]
    })
  end

  # ============================================================
  # PRUEBAS DE GUARDADO
  # ============================================================

  test "guarda correctamente el estado en un archivo" do
    path = temporary_path()

    assert :ok = Storage.save(sample_state(), path)
    assert File.exists?(path)

    File.rm(path)
  end

  test "rechaza un estado inválido" do
    path = temporary_path()

    assert {:error, :invalid_state} = Storage.save(%{}, path)
    refute File.exists?(path)
  end

  test "rechaza una ruta inválida" do
    assert {:error, :invalid_path} = Storage.save(sample_state(), "")
  end

  # ============================================================
  # PRUEBAS DE RECUPERACIÓN
  # ============================================================

  test "recupera el estado guardado correctamente" do
    path = temporary_path()
    state = sample_state()

    assert :ok = Storage.save(state, path)
    assert {:ok, recovered_state} = Storage.load(path)

    assert recovered_state == state

    File.rm(path)
  end

  test "conserva las estructuras especiales del estado" do
    path = temporary_path()
    state = sample_state()

    assert :ok = Storage.save(state, path)
    assert {:ok, recovered_state} = Storage.load(path)

    assert is_struct(recovered_state.active_users, MapSet)
    assert MapSet.member?(recovered_state.active_users, "usuario1")

    assert Map.has_key?(
             recovered_state.resource_stocks,
             {"R001", "centro_norte"}
           )

    [activity | _] = recovered_state.activity_log

    assert is_struct(activity.timestamp, DateTime)
    assert activity.action == :register_resource

    File.rm(path)
  end

  test "retorna error cuando el archivo no existe" do
    path = temporary_path()

    assert {:error, :enoent} = Storage.load(path)
  end

  test "rechaza archivos con formato incorrecto" do
    path = temporary_path()

    File.write!(path, "ARCHIVO_INVALIDO")

    assert {:error, :invalid_file_format} = Storage.load(path)

    File.rm(path)
  end

  test "rechaza contenido que no está codificado en Base64" do
    path = temporary_path()

    File.write!(path, "EMERGENCY_SYSTEM_V1\ncontenido_invalido")

    assert {:error, :corrupted_file} = Storage.load(path)

    File.rm(path)
  end

  # ============================================================
  # PRUEBAS DE CONSULTA
  # ============================================================

  test "comprueba si un archivo de persistencia existe" do
    path = temporary_path()

    refute Storage.exists?(path)

    File.write!(path, "contenido")

    assert Storage.exists?(path)

    File.rm(path)
  end

  test "retorna false cuando la ruta no es válida" do
    refute Storage.exists?("")
  end
end
