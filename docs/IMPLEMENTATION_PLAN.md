# dbToolKit implementation plan

## Execution boundary

Prepare the project, then **stop before the first configure or build command**:
either may trigger vcpkg compilation. The user performs the initial build and
reports the result before implementation continues. This checkpoint is active.

## Source layout and tracking

Paths are relative to `dbToolkit-qt/`.

- C++ application sources: `src/`, organized by responsibility.
- QML: `src/qml/`; assets: `resources/`; tests: `tests/`.
- CMake configuration and `vcpkg.json`: project root.
- Use only one `build/` directory.
- Maintain this file and follow the tracking instructions in `AGENTS.md`.
- Keep stable step IDs. Mark `[x]` only after the stated acceptance checks pass.
- Leave partial steps unchecked, with completed substeps and pending checks listed.
- Update Handoff after every session with work, evidence, blockers, and next action.
- Never count unavailable or unrun tests as passing.

## Before the first build

- [x] **P00 — Persist the plan and tracking rules.** Save the agreed decisions and user-controlled first-build checkpoint; update `AGENTS.md` to require progress maintenance.
- [x] **P01a — Prepare the build foundation.** Move C++ to `src/`, QML to `src/qml/`, and assets to `resources/`. Fix the `QtCustomDemo`/`DbToolKit` module mismatch and replace demo branding. Configure C++20, Qt Quick Controls, Catch2/CTest, and the declared dependencies using the unchanged pinned baseline. Acceptance here is source preparation and inspection, not a successful build; that is P01d.
- [x] **P01b — Prepare reproducible build instructions.** Document exact PowerShell commands using the installed Qt MinGW kit, matching vcpkg MinGW triplets, Ninja, and `build/`. Inspect paths, package targets, and QML registration without configuring, compiling, or installing dependencies.
- [ ] **P01c — STOP for the user's first build.** Handoff is ready; await the user's configure/build/test output and confirmation that the window opens. Expected application: `build/DbToolKit.exe`. Commands are in `README.md`. Do not resume backend work yet.
- [ ] **P01d — Validate the foundation after the user responds.** Resolve reported build issues, confirm the application opens, and verify CTest. Only then continue below.

## Remaining implementation

- [ ] **P02 — Application architecture.** Create focused vault, connection, database, service, and export components. Use one small database interface with PostgreSQL and MySQL/MariaDB implementations. Expose typed controllers and Qt item models to QML. Define connection profiles, database summaries, table metadata, row identities, capabilities, and operation results. Keep SQL and secrets in C++; keep blocking work off the UI thread and worker connections privately owned. Suppress stale results after navigation, disconnect, or locking. Never automatically retry mutations. Acceptance: asynchronous success/failure does not freeze the UI or update an obsolete screen.
- [ ] **P03 — Dark-only interface.** Build reusable charcoal controls with restrained blue accents, compact tables, clear focus states, and subtle transitions. Use Segoe UI and monospace values. Implement Unlock -> Services/connections -> Server databases -> Database details/viewer, with breadcrumbs, connection context, and Lock. Support loading, empty, and error states, native window controls, keyboard navigation, and scaling. Default 1280x800, minimum 1000x650. Acceptance: all main screens are coherent and accessible with no light-theme controls or demo content. The current shell is only the P01 foundation, not completion of P03.
- [ ] **P04 — Encrypted vault.** Use SQLite in the user's application-data directory with libsodium Argon2id, a wrapped random vault key, and authenticated record encryption with fresh nonces. Persist versioned crypto parameters and make updates atomic. Encrypt connection details, credentials, notes, and identifying metadata; only non-sensitive preferences and encryption metadata remain open. Implement setup, unlock, manual lock, password change, and Windows session locking. No idle timeout. Hide sensitive views immediately, invalidate pending results, close connections, and clear secrets once active operations safely settle. No password recovery: explicitly confirmed vault reset leaves server databases untouched. Acceptance: wrong passwords and tampering fail safely; password changes survive restart; no plaintext secrets in storage/logs; locked UI cannot access secrets.
- [ ] **P05 — Saved connections.** Implement create, edit, test, select, remove, password reveal, and copy for all three local engines. Support local host, port, engine, credentials, and PostgreSQL maintenance database. Separate administrative credentials from project credentials. Allow saving while a service is stopped; testing is independently available. Acceptance: profiles survive restart, all three engines connect, and stopped services, invalid credentials, and missing privileges produce actionable errors.
- [ ] **P06 — Windows services.** Detect existing database executables without relying solely on service display names. Associate services with connections and show running/stopped/pending/unavailable states. Start/stop normally where permitted; otherwise use a narrowly scoped elevated helper that independently validates the service and start/stop action. Keep the main app unelevated. Support manual connections without detected services, refresh, and reconnect. Acceptance: multiple instances, UAC cancellation, access denial, and timeouts work; unrelated services cannot be controlled through the helper.
- [ ] **P07 — Database overview.** Show databases, size, table count, engine, managed status, schemas/tables, server settings/version, notes, and ownership where meaningful. Do not imply PostgreSQL-style ownership for MySQL. Load expensive statistics asynchronously and report unavailable values honestly. Acceptance: limited privileges and external changes do not break the whole page; refresh shows current state.
- [ ] **P08 — Creation and adoption.** Create databases with dedicated least-privilege users, generated passwords, and server-supported encoding/collation settings. Track partial server operations and preserve recoverable credentials; only compensate resources created by the operation. Persist managed state after confirmed server results. Adoption records supplied credentials without changing ownership or grants. Track whether the app created an associated user. Acceptance: project credentials access the intended database, adoption makes no server changes, and interrupted creation cannot silently lose credentials or claim success.
- [ ] **P09 — Maintenance.** Implement notes, managed-user password changes, empty database, recreate, and delete. Empty preserves schema; recreate removes all objects and produces a fresh database with recorded settings and project-user grants. Confirm exact destructive effects and targets, require typed names for database-wide destruction, and block system databases. Default optional user deletion off; block removal of shared users or when safety cannot be established. Do not silently terminate other clients or cascade outside the selected target. Acceptance: foreign keys, active sessions, partial failures, and password-update failures leave accurate server/vault state and recovery guidance.
- [ ] **P10 — Table browsing.** Provide schema/table navigation, column details, virtualized 100-row pages, server-side typed filters/sorting, and cell inspection/copy. Parameterize values and quote identifiers per engine. Use stable key ordering where available and explain page instability for tables without keys. Distinguish NULL, empty strings, binary values, and long text. Acceptance: large tables remain responsive; Unicode, quotes, nulls, dates, and numeric filtering work.
- [ ] **P11 — Editing.** Support explicit save/cancel for supported scalar values, empty strings where valid, and a separate Set NULL action. Require primary keys or suitable non-null unique keys for editing/deleting. Use transactions, original-value conflict checks, and affected-row checks; keep unsupported/generated/binary values read-only. Confirm row deletion and table emptying without cascading into unselected tables. Acceptance: composite keys work, concurrent changes are reported, and ambiguous rows cannot be modified.
- [ ] **P12 — Export and connection strings.** Discover compatible installed pg_dump, mysqldump, and mariadb-dump utilities with manual path selection and engine/version checks. Export schema/data to SQL without global-user creation. Run without a shell, keep credentials out of process arguments/logs, and protect and clean temporary credential files. Support cancellation and overwrite confirmation; write partial output and finalize only on success. Generate correctly escaped connection URIs. Acceptance: each engine's export restores into a disposable database; incomplete files are never reported as complete.
- [ ] **P13 — Tray workflow.** Add Show, Lock, and Quit using QApplication and notification-area support. Close minimizes to tray; without a tray it exits. Handle active mutations deliberately during shutdown and exclude credentials from notifications. Acceptance: restore, lock, quit, Windows session lock, and service disappearance behave consistently.
- [ ] **P14 — Validate and package.** Produce a portable release folder under build containing Qt/QML and native runtime dependencies, licenses, usage instructions, export-tool setup, compatibility information, and troubleshooting. Validate MySQL 8.4, MariaDB 11.4, and PostgreSQL 16-18. Acceptance: the package works on Windows without developer tools and every PRD feature has recorded evidence.

## Acceptance and defaults

- Focused automated checks: vault tampering/migrations, SQL quoting/binding, URI escaping, row identities/conflicts, partial-operation recovery, model transitions, and stale asynchronous results.
- Use explicitly configured disposable databases for destructive integration tests and export/restore verification. Never use an existing project database for those tests.
- Manual checks: keyboard use, resizing, 100/150/200% scaling, long identifiers, large tables, connection loss, missing utilities, UAC cancellation, and locking during operations.
- Inspect logs, local storage, process arguments, temporary files, and post-lock UI for credential exposure.
- Full PRD scope; existing installations and local connections only; elevation only for service control; portable delivery with app data in the user profile.
- No server installation, remote administration, SQL console, import, schema design, or row insertion in this release.
- Keep interfaces small and use composition. Share engine implementations only where the behavior is genuinely common; represent engine capabilities explicitly.

## Handoff

- **Updated:** 2026-09-08.
- **Current step:** P01c, waiting for the user's first build.
- **Completed:** P00, P01a, P01b. Reorganized sources/assets, corrected QML registration with a Main.qml resource alias, added a minimal dark branded shell, wired manifest dependencies and Catch2/CTest, registered a Windows icon, and documented configure/build/test/launch commands.
- **Static evidence:** Inspected Qt 6.11.1 kit metadata (GCC 13.1), installed GCC/Ninja/CMake paths, the pinned libpqxx port, and vcpkg sodium/SQLite/MariaDB CMake exports. Reviewed changed paths and source registration. Manifest/baseline unchanged. Static diff checks passed.
- **Tests:** Two dependency smoke tests are prepared (SQLite in-memory open and libsodium authenticated round-trip/tamper rejection). Neither has run. They validate runtime linkage, not future product features.
- **Not run:** CMake configure, dependency installation, build, CTest, QML runtime, or visual verification. No build directory was created.
- **Blocker/checkpoint:** User explicitly owns the first configure/build. Compatibility of the pinned dependency set with MinGW remains unverified until that completes.
- **Exact next action:** User follows README First build commands and reports results. Then resolve any reported failures and complete P01d before P02. Retire the temporary first-build restriction in AGENTS.md only when the user authorizes continuation.
