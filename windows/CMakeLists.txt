cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "agora_rtc_engine")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "agora_rtc_engine_plugin")

add_library(${PLUGIN_NAME} SHARED
  "agora_rtc_engine_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/sdk/include")
find_library(AGORA_RTC_LIB agora_rtc_sdk "${CMAKE_CURRENT_SOURCE_DIR}/sdk/lib")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin ${AGORA_RTC_LIB})

# List of absolute paths to libraries that should be bundled with the plugin
set(agora_rtc_engine_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/sdk/dll/agora_rtc_sdk.dll"
  PARENT_SCOPE
)
