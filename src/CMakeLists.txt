# Add gemdos
add_subdirectory(gemdos)

set(TOSBINDL_LIBRARY_NAME tosbindl)

add_library(${TOSBINDL_LIBRARY_NAME} STATIC
  tosbindl.c
)

# tosbindl.h is the public header
set(TOSBINDL_PUBLIC_HEADERS "${CMAKE_SOURCE_DIR}/src/tosbindl.h")
set_target_properties(${TOSBINDL_LIBRARY_NAME} PROPERTIES PUBLIC_HEADER "${TOSBINDL_PUBLIC_HEADERS}")

# Install the tosbindl library and public header
install(TARGETS ${TOSBINDL_LIBRARY_NAME} ARCHIVE DESTINATION lib PUBLIC_HEADER DESTINATION include)
