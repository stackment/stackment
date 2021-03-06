cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "skmtdart")
project(${PROJECT_NAME} LANGUAGES CXX)

#set(CMAKE_VERBOSE_MAKEFILE ON)


find_library(SKMTFFI_LIB skmtdart_ffi HINTS "${PROJECT_SOURCE_DIR}/../packages/skmtdart_ffi/linux/")

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "skmtdart_plugin")

#set(SKMTDART_STATIC_LIB "${PROJECT_SOURCE_DIR}/../packages/skmtdart_ffi/linux/libskmtdart_ffi.so")
#set(SKMTDART_STATIC_LIB_NAME "libskmtdart_ffi.so")

#set(DUMMY_LIB, "${PROJECT_SOURCE_DIR}/../packages/skmtdart_ffi/linux/libskmtdart_ffi.so")
#set(SKMT_FFI_LIB, "/home/cytrinox/src/dartrust/skmtdart/packages/skmtdart_ffi/linux/libskmtdart_ffi.so")

add_library(${PLUGIN_NAME} SHARED
  "skmtdart_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
#target_link_libraries(${PLUGIN_NAME} PRIVATE "${SKMT_FFI_LIB}")
target_link_libraries(${PLUGIN_NAME} PUBLIC "${SKMTFFI_LIB}")

#target_link_libraries(${PLUGIN_NAME} PUBLIC "${DUMMY_LIB}")

# List of absolute paths to libraries that should be bundled with the plugin
set(skmtdart_bundled_libraries
"${SKMTFFI_LIB}"
  PARENT_SCOPE
)
