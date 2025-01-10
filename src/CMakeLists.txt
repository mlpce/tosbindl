# Add gemdos
add_subdirectory(gemdos)

set(TOSBINDL_LIBRARY_NAME tosbindl)

add_library(${TOSBINDL_LIBRARY_NAME} STATIC
  tosbindl.c
)

# Install the tosbindl library and public header
install(TARGETS ${TOSBINDL_LIBRARY_NAME} ARCHIVE DESTINATION lib)
