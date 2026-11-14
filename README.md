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

Requisitos:
- Elixir.
- Erlang/OTP.
- Git.

Clonar el repositorio:

```bash
git clone URL_DEL_REPOSITORIO
```

Entrar al proyecto:

```bash
cd emergency-system-elixir
```

Instalar dependencias:

```bash
mix deps.get
```

Compilar:

```bash
mix compile
```

Ejecutar las pruebas:

```bash
mix test
```

## Equipo de trabajo

- Yvette Daniela Campo Osorio
- Sofia Aviles Diaz
- Santiago Barrero Lopez

## Asignatura

Programación III  
Ingeniería de Sistemas y Computación  
Universidad del Quindío

**Año:** 2026