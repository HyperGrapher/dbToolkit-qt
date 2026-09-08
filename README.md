# dbToolKit

A dark Qt Quick workspace for local MySQL, MariaDB, and PostgreSQL databases.
The current version is a navigable **UI preview with fictional sample data**.
There are no database connections, service changes, SQL exports, saved credentials,
or vault/password screens in this preview.

## Open the preview — no build required

From the project directory, run:

```powershell
.\tools\Preview.ps1
```

The launcher uses `qml.exe` from your Qt MinGW installation on PATH. It copies the
QML module into `build/ui-preview/` and opens it directly using Qt's Basic style.
It does **not** invoke CMake, vcpkg, a compiler, or dependency installation.
Rerun it after QML changes to refresh the preview. Close the previous preview window
before relaunching if you want only one window.

Explore:

- **Overview:** service cards, database search, managed filter, selection, and details.
- **Connections:** sample local servers and connection forms. The next UI pass adds
  administrator password capture and aligns trailing connection actions.
- **Table viewer:** sample users, local filtering, table navigation, Data/Structure tabs,
  and cell selection/inspection. The next pass requires an explicit database selection.
- **Exports:** illustrative export history and SQL import/export dialogs. Trailing
  metadata/actions will use fixed alignment columns.
- **Settings:** Midnight, Sublime Text Default Dark, and Nord theme choices.
- **Dialogs:** creation, adoption, editing, export, and destructive-action previews.

Navigation and sample selection work in memory. Action buttons either open a
preview dialog or explain that the action is not connected. Submitting a dialog
makes no database, file, or system changes. `Ctrl+1`, `Ctrl+2`, and `Ctrl+3` open
Overview, Connections, and Table Viewer respectively.

The previous `build/DbToolKit.exe` is still the last compiled version. Use the
preview launcher to see the new design without compiling it.

## Build policy

The user completed the initial MinGW build and dependency tests. A subsequent
CMake regeneration started a dependency rebuild after the build environment
changed; it was stopped at the user's request. All 18 original packages were
restored from existing binary archives matching the original installation ABIs.
The restored installation is recognized by vcpkg and the existing tests pass.
Recovery metadata is preserved under `build/ui-preview/dependency-recovery/`.

Automatic dependency installation is now **off by default**:

- `DBTOOLKIT_UI_PREVIEW=ON` keeps a compiled preview Qt-only.
- `DBTOOLKIT_INSTALL_DEPENDENCIES=OFF` disables vcpkg installation before `project()`
  runs, including during automatic CMake regeneration.
- Turning off UI preview mode requires already installed backend libraries.
- Do not enable dependency installation without the user's explicit authorization.

The new CMake configuration has been inspected but deliberately not configured or
built after the stop request. The QML preview has been validated directly instead.
Always use the existing `build/` directory. Do not create another build tree.

## Validation

QML sources are checked with `qmlformat` and `qmllint`. Runtime screenshot checks
cover all five screens and creation/connection/export/destructive dialogs at
1440×900, plus constrained layouts at 1000×650. Captures and logs are under
`build/ui-preview/`.

The existing C++ dependency smoke tests can be run without compiling:

```powershell
ctest --test-dir build --output-on-failure
```

Those tests validate the SQLite and libsodium runtimes, not UI or future backend
features. They are omitted from a newly configured Qt-only preview build.

## Implementation order

See [the PRD](docs/PRD.md) and [the implementation checklist](docs/IMPLEMENTATION_PLAN.md).
Update and review the UI first, then implement backend workflows. Planned additions
include SQL import/merge, offline cached database summaries, first-use administrator
credentials, explicit Table Viewer database selection, and three dark themes.
The encrypted vault and
all lock/master-password screens are deferred until after P13 and before final
release validation. Real development credentials must remain session-only until
the vault is available.

## Layout

- `src/`: C++ application code.
- `src/qml/`: QML screens, shared controls, theme, and isolated preview fixtures.
- `resources/`: images and Windows executable icon.
- `tests/`: Catch2 dependency tests.
- `tools/`: the no-build QML preview launcher.
- `docs/`: requirements and progress.
- `build/`: the only generated build directory, including local vcpkg and preview output.

Qt comes from the installed Qt SDK. The dependency manifest and baseline are unchanged.
No additional library is planned for the new requirements. SQL import/export will use
the compatible database client utilities installed on the machine; Qt provides the
remaining process, file, model, settings, and theme support.
