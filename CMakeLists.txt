cmake_minimum_required(VERSION 3.24)

option(DBTOOLKIT_UI_PREVIEW "Build the Qt-only design preview" ON)
option(DBTOOLKIT_INSTALL_DEPENDENCIES "Explicitly allow vcpkg to install/rebuild dependencies" OFF)
# Set before project(): the vcpkg toolchain otherwise installs during regeneration.
set(VCPKG_MANIFEST_INSTALL ${DBTOOLKIT_INSTALL_DEPENDENCIES})

project(DbToolKit VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2)
if(NOT DBTOOLKIT_UI_PREVIEW)
    find_package(nlohmann_json CONFIG REQUIRED)
    find_package(spdlog CONFIG REQUIRED)
    find_package(unofficial-sodium CONFIG REQUIRED)
    find_package(unofficial-sqlite3 CONFIG REQUIRED)
    find_package(libpqxx CONFIG REQUIRED)
    find_package(unofficial-libmariadb CONFIG REQUIRED)
endif()

qt_standard_project_setup(REQUIRES 6.5)

add_library(DbToolKitCore STATIC
    src/core/AppLog.cpp
    src/core/AppLog.h
    src/core/DomainTypes.cpp
    src/core/DomainTypes.h
    src/core/DatabaseDriver.cpp
    src/core/DatabaseDriver.h
    src/core/SessionCredentialStore.cpp
    src/core/SessionCredentialStore.h
    src/core/CachedSnapshotStore.cpp
    src/core/CachedSnapshotStore.h
    src/core/StaleResultGate.cpp
    src/core/StaleResultGate.h
    src/models/ConnectionListModel.cpp
    src/models/ConnectionListModel.h
    src/models/ColumnListModel.cpp
    src/models/ColumnListModel.h
    src/models/DatabaseListModel.cpp
    src/models/DatabaseListModel.h
    src/models/ServiceListModel.cpp
    src/models/ServiceListModel.h
    src/models/TableListModel.cpp
    src/models/TableListModel.h
    src/models/RowTableModel.cpp
    src/models/RowTableModel.h
    src/services/WindowsDatabaseService.cpp
    src/services/WindowsDatabaseService.h
    src/controllers/ApplicationController.cpp
    src/controllers/ApplicationController.h
)
target_include_directories(DbToolKitCore PUBLIC src)
target_link_libraries(DbToolKitCore PUBLIC Qt6::Core Qt6::Gui)
if(WIN32)
    target_link_libraries(DbToolKitCore PRIVATE advapi32 shell32)
endif()
if(NOT DBTOOLKIT_UI_PREVIEW)
    target_compile_definitions(DbToolKitCore PRIVATE DBTOOLKIT_WITH_DATABASE_DRIVERS=1)
    target_link_libraries(DbToolKitCore PRIVATE
        libpqxx::pqxx
        unofficial::libmariadb
    )
endif()

qt_add_executable(DbToolKit WIN32
    src/main.cpp
)

if(WIN32)
    target_sources(DbToolKit PRIVATE resources/app.rc)
    target_include_directories(DbToolKit PRIVATE resources)
endif()

set(app_qml_files
    src/qml/Main.qml
    src/qml/Theme.qml
    src/qml/Glyph.qml
    src/qml/ActionButton.qml
    src/qml/Tag.qml
    src/qml/SearchInput.qml
    src/qml/ServiceCard.qml
    src/qml/DatabaseInspector.qml
    src/qml/WorkspacePage.qml
    src/qml/ConnectionsPage.qml
    src/qml/ViewerPage.qml
    src/qml/ExportsPage.qml
    src/qml/SettingsPage.qml
    src/qml/PreviewDialog.qml
)
set_source_files_properties(src/qml/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)
# Keep types at the module root even though sources live under src/qml.
foreach(qml_file IN LISTS app_qml_files)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()
qt_add_qml_module(DbToolKit
    URI DbToolKit
    VERSION 1.0
    QML_FILES ${app_qml_files}
)

target_link_libraries(DbToolKit
    PRIVATE 
        Qt6::Quick
        Qt6::QuickControls2
        DbToolKitCore
)
if(NOT DBTOOLKIT_UI_PREVIEW)
    target_link_libraries(DbToolKit PRIVATE
        nlohmann_json::nlohmann_json
        spdlog::spdlog
        unofficial-sodium::sodium
        unofficial::sqlite3::sqlite3
        libpqxx::pqxx
        unofficial::libmariadb
    )
endif()

include(CTest)
if(BUILD_TESTING AND NOT DBTOOLKIT_UI_PREVIEW)
    find_package(Catch2 3 CONFIG REQUIRED)
    add_subdirectory(tests)
endif()
