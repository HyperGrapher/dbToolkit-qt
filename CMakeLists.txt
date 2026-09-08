cmake_minimum_required(VERSION 3.24)

project(DbToolKit VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(unofficial-sodium CONFIG REQUIRED)
find_package(unofficial-sqlite3 CONFIG REQUIRED)
find_package(libpqxx CONFIG REQUIRED)
find_package(unofficial-libmariadb CONFIG REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(DbToolKit WIN32
    src/main.cpp
)

if(WIN32)
    target_sources(DbToolKit PRIVATE resources/app.rc)
    target_include_directories(DbToolKit PRIVATE resources)
endif()

# Keep Main at the module root even though sources live under src/qml.
set_source_files_properties(src/qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
qt_add_qml_module(DbToolKit
    URI DbToolKit
    VERSION 1.0
    QML_FILES src/qml/Main.qml
)

target_link_libraries(DbToolKit
    PRIVATE 
        Qt6::Quick
        Qt6::QuickControls2
        nlohmann_json::nlohmann_json
        spdlog::spdlog
        unofficial-sodium::sodium
        unofficial::sqlite3::sqlite3
        libpqxx::pqxx
        unofficial::libmariadb
)

include(CTest)
if(BUILD_TESTING)
    find_package(Catch2 3 CONFIG REQUIRED)
    add_subdirectory(tests)
endif()
