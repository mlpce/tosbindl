set(GEMPB_LIBRARY_NAME "tbgempb")

set(GEMPB_SRCS
  tbgempb.c
)

add_library(${GEMPB_LIBRARY_NAME} STATIC
  ${GEMPB_SRCS}
)

# tbgem.h is the public header
set(TBGEMPB_PUBLIC_HEADERS "${CMAKE_SOURCE_DIR}/src/gempb/tbgempb.h")
set_target_properties(${GEMPB_LIBRARY_NAME} PROPERTIES PUBLIC_HEADER "${TBGEMPB_PUBLIC_HEADERS}")

# Install the tbgem library and public header
install(TARGETS ${GEMPB_LIBRARY_NAME} ARCHIVE DESTINATION lib PUBLIC_HEADER DESTINATION include)
