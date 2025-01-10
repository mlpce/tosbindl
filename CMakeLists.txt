cmake_minimum_required(VERSION 3.22)

project(tosbindl VERSION 1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 90)

if ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU" )
  # Using GCC
  set(CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} -Wall -Wextra -Wno-unused-parameter -pedantic -Wconversion")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMLPCE_ENABLED")

include_directories(".")
include_directories("${CMAKE_INSTALL_PREFIX}/include")

# Add src
add_subdirectory(src)
