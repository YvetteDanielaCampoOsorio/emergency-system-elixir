defmodule EmergencySystem.People.PersonManager do
  @moduledoc """
  Módulo encargado de registrar y consultar personas afectadas
  durante una situación de emergencia.

  Permite registrar personas y buscarlas mediante su identificador,
  nombre, documento o dato de referencia, zona y estado.

  ## Información del módulo

  - Versión: 1.0
  - Autores: Yvette Daniela Campo Osorio, Sofia Aviles Diaz, Santiago Barrero Lopez
  - Fecha: noviembre de 2026
  - Licencia: GNU GPL v3
  """

  @valid_statuses [
    :no_information,
    :reported,
    :located,
    :transferred,
    :in_shelter,
    :reunified
  ]

  @valid_transitions %{
    no_information: [:reported],
    reported: [:located],
    located: [:transferred, :in_shelter, :reunified],
    transferred: [:in_shelter, :reunified],
    in_shelter: [:transferred, :reunified],
    reunified: []
  }

  # --------------------------------------------------
  # REGISTRO DE PERSONAS
  # --------------------------------------------------

  @doc """
  Registra una persona afectada en el sistema.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `id`: identificador único de la persona.
  - `name`: nombre completo.
  - `reference`: documento o dato de referencia.
  - `age`: edad de la persona.
  - `zone_code`: código de la zona donde fue reportada.
  - `status`: estado inicial de la persona.

  ## Retorna

  - `{:ok, updated_state, person}` si el registro es exitoso.
  - `{:error, reason}` si ocurre una validación fallida.
  """
  def register_person(state, id, name, reference, age, zone_code, status) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <-
           valid_fields?(id, name, reference, zone_code) ||
             {:error, :empty_fields},
         true <-
           (is_integer(age) and age >= 0) ||
             {:error, :invalid_age},
         true <-
           status in @valid_statuses ||
             {:error, :invalid_status},
         true <-
           not Map.has_key?(state.people, id) ||
             {:error, :duplicate_person},
         true <-
           Map.has_key?(state.zones, zone_code) ||
             {:error, :zone_not_found} do
      person = %{
        id: id,
        name: name,
        reference: reference,
        age: age,
        zone_code: zone_code,
        status: status
      }

      updated_people = Map.put(state.people, id, person)
      updated_state = Map.put(state, :people, updated_people)

      {:ok, updated_state, person}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_arguments}
    end
  end

  # --------------------------------------------------
  # FUNCIONES AUXILIARES
  # --------------------------------------------------

  defp valid_state?(state) when is_map(state) do
    is_map(Map.get(state, :people)) and
      is_map(Map.get(state, :zones))
  end

  defp valid_state?(_state), do: false

  defp valid_fields?(id, name, reference, zone_code) do
    Enum.all?(
      [id, name, reference, zone_code],
      fn field ->
        is_binary(field) and String.trim(field) != ""
      end
    )
  end

  # --------------------------------------------------
  # BÚSQUEDA DE PERSONAS
  # --------------------------------------------------

  @doc """
  Busca personas afectadas utilizando uno o varios filtros.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `filters`: mapa con los filtros opcionales:
    - `:name`: búsqueda parcial por nombre.
    - `:document`: búsqueda exacta por documento o referencia.
    - `:zone_code`: búsqueda por código de zona.
    - `:status`: búsqueda por estado.

  ## Retorna

  - `{:ok, people}` con las personas encontradas.
  - `{:error, reason}` si los filtros o el estado son inválidos.

  ## Ejemplo

      search_people(state, %{name: "Andres", status: :reported})
  """
  def search_people(state, filters \\ %{}) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <- valid_filters?(filters) || {:error, :invalid_filters} do
      people =
        state.people
        |> Map.values()
        |> Enum.filter(fn person ->
          matches_filters?(person, filters)
        end)

      {:ok, people}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # --------------------------------------------------
  # VALIDACIÓN Y COMPARACIÓN DE FILTROS
  # --------------------------------------------------

  defp valid_filters?(filters) when is_map(filters) do
    valid_keys = [:name, :document, :zone_code, :status]

    Enum.all?(Map.keys(filters), &(&1 in valid_keys)) and
      Enum.all?(filters, fn
        {:name, value} -> valid_text_filter?(value)
        {:document, value} -> valid_text_filter?(value)
        {:zone_code, value} -> valid_text_filter?(value)
        {:status, value} -> value in @valid_statuses
        _ -> false
      end)
  end

  defp valid_filters?(_filters), do: false

  defp valid_text_filter?(value) do
    is_binary(value) and String.trim(value) != ""
  end

  defp matches_filters?(person, filters) do
    name_matches =
      case Map.get(filters, :name) do
        nil ->
          true

        name ->
          String.contains?(
            String.downcase(person.name),
            String.downcase(name)
          )
      end

    document_matches =
      case Map.get(filters, :document) do
        nil -> true
        document -> person.reference == document
      end

    zone_matches =
      case Map.get(filters, :zone_code) do
        nil -> true
        zone_code -> person.zone_code == zone_code
      end

    status_matches =
      case Map.get(filters, :status) do
        nil -> true
        status -> person.status == status
      end

    name_matches and document_matches and
      zone_matches and status_matches
  end

  # --------------------------------------------------
  # ACTUALIZACIÓN DEL ESTADO DE PERSONAS
  # --------------------------------------------------

  @doc """
  Actualiza el estado de una persona y registra el cambio
  en el historial del sistema.

  ## Parámetros

  - `state`: estado actual del sistema.
  - `person_id`: identificador de la persona.
  - `new_status`: nuevo estado que se desea asignar.

  ## Retorna

  - `{:ok, updated_state, person}` si la actualización es exitosa.
  - `{:error, reason}` si ocurre una validación fallida.
  """
  def update_person_status(state, person_id, new_status) do
    with true <- valid_state?(state) || {:error, :invalid_state},
         true <-
           (is_binary(person_id) and person_id != "") ||
             {:error, :invalid_id},
         true <-
           new_status in @valid_statuses ||
             {:error, :invalid_status},
         {:ok, person} <- find_person(state, person_id),
         true <-
           new_status in Map.get(@valid_transitions, person.status, []) ||
             {:error, :invalid_transition} do
      updated_person = Map.put(person, :status, new_status)

      updated_people =
        Map.put(state.people, person_id, updated_person)

      history_entry = %{
        person_id: person_id,
        previous_status: person.status,
        new_status: new_status,
        timestamp: DateTime.utc_now()
      }

      updated_history =
        [history_entry | Map.get(state, :person_status_history, [])]

      updated_state =
        state
        |> Map.put(:people, updated_people)
        |> Map.put(:person_status_history, updated_history)

      {:ok, updated_state, updated_person}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_arguments}
    end
  end

  # --------------------------------------------------
  # FUNCIONES AUXILIARES DE ESTADO
  # --------------------------------------------------

  defp find_person(state, person_id) do
    case Map.fetch(state.people, person_id) do
      {:ok, person} -> {:ok, person}
      :error -> {:error, :person_not_found}
    end
  end
end
