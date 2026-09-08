add_executable(DbToolKitTests DependencySmokeTests.cpp)
target_link_libraries(DbToolKitTests PRIVATE
    Catch2::Catch2WithMain
    unofficial-sodium::sodium
    unofficial::sqlite3::sqlite3
)

include(Catch)
# Defer discovery until CTest, when the documented runtime PATH is available.
catch_discover_tests(DbToolKitTests DISCOVERY_MODE PRE_TEST)
