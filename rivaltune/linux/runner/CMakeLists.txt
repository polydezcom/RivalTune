cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Ensure icons are generated before building the native runner.
add_dependencies(${BINARY_NAME} generate_icons)

# After building the binary, copy desktop file and icons into the bundle's
# data directory so `flutter build linux` produces a bundle that includes them.
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bundle/data"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_SOURCE_DIR}/../rivaltune.desktop"
    "${CMAKE_BINARY_DIR}/bundle/data/rivaltune.desktop"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_BINARY_DIR}/bundle/data/icons"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_CURRENT_SOURCE_DIR}/../icons/hicolor"
    "${CMAKE_BINARY_DIR}/bundle/data/icons/hicolor"
  COMMENT "Copying desktop file and icons into bundle data"
)
