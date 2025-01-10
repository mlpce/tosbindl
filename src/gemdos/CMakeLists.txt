set(GEMDOS_LIBRARY_NAME "tbgemdos")

set(GEMDOS_SRCS
  tbgemdos.c
  gemdosi.c
  gemdos_c.c
  gemdos_d.c
  gemdos_f.c
  gemdos_m.c
  gemdos_p.c
  gemdos_s.c
  gemdos_t.c
)

add_library(${GEMDOS_LIBRARY_NAME} STATIC
  ${GEMDOS_SRCS}
)

# tbgemdos.h is the public header
set(TBGEMDOS_PUBLIC_HEADERS "${CMAKE_SOURCE_DIR}/src/gemdos/tbgemdos.h")
set_target_properties(${GEMDOS_LIBRARY_NAME} PROPERTIES PUBLIC_HEADER "${TBGEMDOS_PUBLIC_HEADERS}")

# Install the tosbindl library and public header
install(TARGETS ${GEMDOS_LIBRARY_NAME} ARCHIVE DESTINATION lib PUBLIC_HEADER DESTINATION include)
