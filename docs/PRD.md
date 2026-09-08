# dbToolKit Product Requirements Document

## Product summary

dbToolKit is a Windows desktop companion for developers who run MySQL,
MariaDB, or PostgreSQL locally. It brings the everyday work of connecting to
database servers, creating project databases, inspecting their contents, and
performing routine maintenance into one focused application.

The product is intended to make local database work feel clear and safe. A
developer should be able to see which servers are available, choose a saved
connection, understand a database at a glance, and complete common tasks
without switching between several command-line tools.

## Problem and opportunity

Local development databases are often managed through a mixture of service
settings, command-line commands, connection strings, and ad-hoc notes about
credentials. This creates friction when starting a new project, returning to
an older one, or checking the data inside a database.

dbToolKit provides one place to manage those local resources while keeping
important actions understandable and deliberate.

## Target users

- Software developers who work with locally installed MySQL, MariaDB, or
  PostgreSQL servers.
- Developers who want to create an isolated database and user for each
  project.
- Developers who need a lightweight way to inspect and make small changes to
  local database data.

## Product goals

- Make local database setup and maintenance quick to understand.
- Keep connection details and saved credentials available only after the user unlocks the app.
- Present database health, content, and ownership in a simple visual workflow.
- Make destructive operations explicit through clear labels and confirmations.
- Support both newly created databases and existing databases the user wants
  to bring under management.

## Key user experience

When the app opens, the user unlocks their local vault. They see the available database services on the system (Mysql Postgres). They select or create a connection to a local database server, ensure its service is running, and then they navigate tomanagement page for that database service, see the databases available on that server. From there, they can create a database for a new project, inspect an existing one, copy its connection details, export it, or perform maintenance actions when needed.

## Core features

### Secure access and saved connections

- Protect saved local credentials with a master password.
- Create, edit, test, select, and remove saved database-server connections.
- Keep connection details for databases managed by the app available for
  viewing and copying when needed.
- Show or hide stored database passwords on demand.

### Local server control

- Detect supported local database services.
- Show whether a detected service is running or stopped.
- Start and stop a service from within the app.
- Refresh service status and reconnect after a service becomes available.

### Database overview

- List the databases on the selected server.
- Show useful summary information such as database name, engine, size, table
  count, and whether dbToolKit manages it.
- Select a database to view its details, including connection information,
  owner, tables, server information, and settings where available.
- Refresh the database list and details after external changes.

### Database lifecycle management

- Create a MySQL, MariaDB, or PostgreSQL database for a project.
- Create a dedicated database user and password during database creation.
- Choose database character and collation settings where supported.
- Save notes about a managed database.
- Adopt an existing database so its connection details can be managed in the app.
- Change the password for a managed database user.
- Empty a database's data, recreate it, or delete it, with confirmation before
  destructive actions.
- Optionally remove the associated database user when deleting a database.

### Data browsing and editing

- Open a database viewer to browse its tables.
- See table information and page through rows of data.
- Filter and sort table data to find records quickly.
- Inspect a selected cell and copy its value.
- Edit supported cell values, including setting a value to empty where
  appropriate.
- Delete an individual row or empty a table after confirmation.

### Export and everyday workflow

- Export a selected database to an SQL file.
- Copy a database connection string for use in an application or another tool.
- Keep the app available from the Windows notification area for quick access.
- Show clear status and error messages for connection, service, and database actions.

## Safety and privacy expectations

- The app must never write plain-text passwords to its logs.
- Stored credentials remain protected until the local vault is unlocked.
- Destructive actions, including deleting databases, deleting rows, and
  emptying tables, require a confirmation step that explains the effect.
- Failures should explain what the user can check next, such as an unavailable
  service or invalid administrator credentials.

## Supported scope

- Windows desktop application.
- Locally installed MySQL, MariaDB, and PostgreSQL servers.
- Development and local-maintenance workflows; it is not intended to replace a
  full enterprise database administration platform.

## Libraries and frameworks used

- Qt6 — desktop user interface.
- SQLite — local application data storage.
- libpqxx — PostgreSQL connectivity.
- MariaDB Connector/C (`libmariadb`) — MySQL and MariaDB connectivity.
- libsodium — credential protection.
- nlohmann/json — JSON handling.
- spdlog — application logging.
- Catch2 — automated tests.

