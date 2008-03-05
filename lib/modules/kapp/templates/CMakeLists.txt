project(<%= @name %>)

find_package(KDE4)
include(KDE4Defaults)

set(<%= @name %>_SRC
    main.cpp
)

include_directories(${KDE4_INCLUDES})

kde4_add_executable(<%= @name %> ${<%= @name %>_SRC})
target_link_libraries(<%= @name %> ${KDE4_KDEUI_LIBS})

install(TARGETS <%= @name %> DESTINATION ${BIN_INSTALL_DIR})
# install(FILES <%= @name %>.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
install(FILES <%= @name %>ui.rc  DESTINATION  ${DATA_INSTALL_DIR}/<%= @name %>)
