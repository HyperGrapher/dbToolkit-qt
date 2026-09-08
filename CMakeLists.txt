cmake_minimum_required(VERSION 3.16)

project(DbToolKit VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add QuickControls2 here
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(DbToolKit WIN32
    main.cpp
)

qt_add_qml_module(DbToolKit
    URI DbToolKit
    VERSION 1.0
    QML_FILES Main.qml
)

target_link_libraries(DbToolKit
    PRIVATE 
        Qt6::Quick
        Qt6::QuickControls2
)
