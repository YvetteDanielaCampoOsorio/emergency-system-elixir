# EmergencySystem

Sistema distribuido de coordinación y gestión de emergencias desarrollado en **Elixir** como proyecto final de la asignatura Programación III de Ingeniería de Sistemas de la Universidad del Quindío.

## Descripción

EmergencySystem es una aplicación que simula una plataforma de coordinación para la atención de emergencias posteriores a un terremoto. Permite gestionar información de personas afectadas, necesidades, recursos, albergues, mascotas perdidas o encontradas y mensajes entre familiares.

El sistema utiliza programación funcional y mecanismos de concurrencia de Elixir para gestionar operaciones simultáneas y mantener la consistencia de la información.

## Funcionalidades

- Gestión y autenticación de usuarios.
- Registro y consulta de zonas, sectores y puntos de atención.
- Registro, búsqueda y seguimiento de necesidades.
- Administración de recursos, inventario y transferencias.
- Asignación de recursos a necesidades.
- Registro y seguimiento de personas afectadas.
- Comunicación mediante mensajes entre familiares.
- Gestión de mascotas perdidas y encontradas.
- Búsqueda de posibles coincidencias entre mascotas.
- Registro de albergues y control de capacidad.
- Persistencia de información en archivos de texto.

## Tecnologías y conceptos

- Elixir.
- Programación funcional.
- Procesos concurrentes y paso de mensajes.
- GenServer.
- Supervisores y árbol de supervisión OTP.
- Estructuras de datos funcionales.
- Persistencia en archivos.
- Pruebas automatizadas con ExUnit.

## Instalación y ejecución

### Requisitos

- Elixir.
- Erlang/OTP.
- Git.

### Clonar el repositorio

```bash
git clone URL_DEL_REPOSITORIO
cd NOMBRE_DEL_REPOSITORIO
```

### Instalar dependencias

```bash
mix deps.get
```

### Compilar el proyecto

```bash
mix compile
```

### Ejecutar las pruebas

```bash
mix test
```

### Ejecutar la demostración

```bash
mix run demo.exs
```

La demostración permite observar el inicio del supervisor, el registro de una zona, un usuario, una necesidad y un recurso, además de la asignación de inventario y el control de disponibilidad.

## Pruebas de concurrencia

El proyecto incluye pruebas para verificar que las operaciones simultáneas mantengan la consistencia del estado, especialmente en:

- Asignación de recursos sin superar el inventario disponible.
- Actualización de reportes de personas sin resolverlos dos veces.
- Confirmación de coincidencias entre reportes de mascotas sin resolverlos dos veces.

## Equipo de trabajo

- Yvette Daniela Campo Osorio
- Sofia Aviles Diaz
- Santiago Barrero Lopez

## Asignatura

Programación III  
Ingeniería de Sistemas y Computación  
Universidad del Quindío

**Año:** 2026