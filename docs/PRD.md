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
- Keep connection details, cached database metadata, and saved credentials available
  automatically on startup, including while a database service is offline.
- Present database health, content, and ownership in a simple visual workflow.
- Make destructive operations explicit through clear labels and confirmations.
- Support both newly created databases and existing databases the user wants
  to bring under management.

## Key user experience

When the app opens, the user immediately sees the supported local
database services. They select or create a server connection. The first connection
requires the administrator username and password needed by that server. When the
service is online, the app refreshes its database list and stores an encrypted
snapshot. When it is offline, the last successful snapshot remains visible with a
clear stale/offline label, and saved credentials and connection strings remain
available. From the selected server and database, the user can create or adopt a
project database, browse its tables, import or export SQL, copy connection details,
or perform maintenance actions.

## Core features

### Secure access and saved connections

- Protect saved credentials automatically using Windows account-bound DPAPI encryption.
- Do not implement a master password, app unlock/lock screens, password recovery,
  or app locking on Windows session changes. Database authentication passwords remain required.
- Create, edit, test, select, and remove saved database-server connections.
- Require an administrator/root password when first connecting to a server that
  needs password authentication. Include masked password fields in connection setup
  and editing, with reveal-on-demand.
- Store administrator and managed project credentials in protected local storage
  so later features can reconnect without repeatedly prompting.
- Keep connection details for databases managed by the app available for
  viewing and copying when needed.
- Show or hide stored database passwords on demand.

### Local server control

- Detect supported local database services.
- Show whether a detected service is running or stopped.
- Start and stop a service from within the app.
- Refresh service status and reconnect after a service becomes available.
- Keep the last successfully refreshed database list available while its service is
  stopped. Offline mode must be visibly marked and must not imply live status.

### Database overview

- List the databases on the selected server.
- Show useful summary information such as database name, engine, size, table
  count, and whether dbToolKit manages it.
- Select a database to view its details, including connection information,
  owner, tables, server information, and settings where available.
- Refresh the database list and details after external changes.
- Cache the database list, connection details, managed status, notes, ownership,
  size, and table-count summary after successful refreshes. Do not cache table rows.

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

- Require the user to select a server connection and database before opening the
  table viewer. Keep the selected database visible in the viewer header and allow
  switching databases through a selector.
- Open the selected database in a viewer to browse its tables.
- See table information and page through rows of data.
- Filter and sort table data to find records quickly.
- Inspect a selected cell and copy its value.
- Edit supported cell values, including setting a value to empty where
  appropriate.
- Delete an individual row or empty a table after confirmation.

### SQL import, export, and everyday workflow

- Export a selected database to an SQL file.
- Import an engine-native plain `.sql` file into a newly created database or merge
  it into an existing selected database.
- Always execute an import against the target database selected in dbToolKit. A
  database name embedded in a dump must not rename, replace, or redirect away from
  that target.
- Before execution, inspect database-level directives such as `CREATE DATABASE`,
  `DROP DATABASE`, MySQL/MariaDB `USE`, and PostgreSQL `\\connect`. Remove recognized
  dump-level target-selection directives and reject dynamic or unrecognized database
  context changes before applying any statements.
- Merge stops at the first SQL error and uses a single transaction where the engine
  supports it. MySQL/MariaDB imports must warn that DDL can commit implicitly and
  report any partially applied statements accurately.
- Show import progress, cancellation, source engine compatibility, success, and a
  concise failure report without exposing credentials or sensitive SQL values.
- Copy a database connection string for use in an application or another tool.
- Keep the app available from the Windows notification area for quick access.
- Show clear status and error messages for connection, service, and database actions.

### Appearance and layout

- Let the user choose among at least three dark themes: dbToolKit Midnight, Sublime
  Text Default Dark, and Nord.
- Apply theme changes immediately and remember the choice locally.
- Keep table/list columns stable and right-align trailing metadata and actions. This
  includes export size/status/location controls and connection status/edit/open
  controls at every supported window size.

## Safety and privacy expectations

- The app must never write plain-text passwords to its logs.
- Stored credentials are encrypted at rest for the current Windows account and loaded
  automatically. App-data removal never deletes server databases.
- Destructive actions, including deleting databases, deleting rows, and
  emptying tables, require a confirmation step that explains the effect.
- Failures should explain what the user can check next, such as an unavailable
  service or invalid administrator credentials.
- SQL import must show the selected target and require confirmation before executing
  a script. Imported scripts run with only the selected connection's privileges.
- Offline database information must show when it was last refreshed and must never
  be presented as current server state.

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
- Windows DPAPI — automatic credential protection (built-in; no new package).
- libsodium — currently declared dependency; not required for DPAPI storage.
- nlohmann/json — JSON handling.
- spdlog — application logging.
- Catch2 — automated tests.

No additional application library is required for the new features. Qt provides
process execution, file I/O, models, settings, and theming. SQL import and export use
the compatible command-line utilities installed with the selected database engine:
`psql`/`pg_dump` for PostgreSQL and `mysql` or `mariadb` plus their dump utilities
for MySQL/MariaDB. Missing utilities are reported with a path-selection action.
