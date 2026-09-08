# dbToolKit

A Windows Qt Quick companion for local MySQL, MariaDB, and PostgreSQL databases.
The current implementation is a dark application shell and build foundation;
database and vault features are not implemented yet.

See [the PRD](docs/PRD.md) and [the implementation checklist](docs/IMPLEMENTATION_PLAN.md).

## First build (user-run checkpoint)

No configuration, dependency installation, compilation, or tests have been run by
the agent. The first configure may take a long time because vcpkg builds dependencies.
Run these commands in PowerShell. Stop if any command fails and share its output.

The commands below match the inspected machine: Qt 6.11.1, GCC 13.1, Ninja,
CMake on PATH, and vcpkg at `C:\Users\burak\vcpkg`. CMake 3.24 or newer is required.
Both vcpkg triplets use MinGW to avoid mixing MSVC libraries with the Qt MinGW kit.
Keep the single `build/` directory; do not reuse a cache configured with another compiler.

### 1. Configure

```powershell
Set-Location 'C:\Users\burak\Projects\desktop-apps\DbToolKit-Qt6\dbToolkit-qt'
$env:VCPKG_ROOT = 'C:\Users\burak\vcpkg'
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;C:\Qt\6.11.1\mingw_64\bin;$env:PATH"

cmake -S . -B build -G Ninja `
    '-DCMAKE_BUILD_TYPE=Release' `
    '-DCMAKE_C_COMPILER=C:/Qt/Tools/mingw1310_64/bin/gcc.exe' `
    '-DCMAKE_CXX_COMPILER=C:/Qt/Tools/mingw1310_64/bin/g++.exe' `
    '-DCMAKE_MAKE_PROGRAM=C:/Qt/Tools/Ninja/ninja.exe' `
    '-DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/mingw_64' `
    '-DCMAKE_TOOLCHAIN_FILE=C:/Users/burak/vcpkg/scripts/buildsystems/vcpkg.cmake' `
    '-DVCPKG_TARGET_TRIPLET=x64-mingw-dynamic' `
    '-DVCPKG_HOST_TRIPLET=x64-mingw-dynamic' `
    '-DBUILD_TESTING=ON'
```

### 2. Build

```powershell
cmake --build build --parallel
```

Expected application: `build\DbToolKit.exe`.
Expected test executable: `build\tests\DbToolKitTests.exe`.

### 3. Test and launch from the same PowerShell session

```powershell
$env:PATH = "$PWD\build\vcpkg_installed\x64-mingw-dynamic\bin;$env:PATH"
ctest --test-dir build --output-on-failure
& .\build\DbToolKit.exe
```

CTest should discover two dependency smoke tests: SQLite opens an in-memory
database, and libsodium authenticates a message and rejects tampering. These do
not connect to or modify a database server and do not validate the future vault.

The app should show a dark dbToolKit window with a sidebar and a
"Workspace foundation" notice. No connection or vault controls are expected yet.
Report configure/build/test results and whether that window opens before the next stage.

These launch instructions use runtime DLLs from PATH for local development.
A self-contained portable folder and deployment verification belong to P14.

## Layout

- `src/`: C++ application code.
- `src/qml/`: QML interface.
- `resources/`: images and Windows executable icon.
- `tests/`: Catch2 tests registered with CTest.
- `docs/`: product requirements and implementation progress.
- `build/`: the only generated build directory, including local vcpkg output.

Qt comes from the installed Qt SDK. Other dependencies use the unchanged
`vcpkg.json` baseline. MinGW triplets are community-maintained; first-build
compatibility with these pinned dependencies remains unverified at this checkpoint.
