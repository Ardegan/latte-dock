add_definitions(-DTRANSLATION_DOMAIN=\"plasma_containmentactions_lattecontextmenu\")

set(contextmenu_SRCS
    generictools.cpp
    layoutmenuitemwidget.cpp
    menu.cpp
)

add_library(plasma_containmentactions_lattecontextmenu MODULE ${contextmenu_SRCS})

#! Plasma 6 resolves containmentactions by file name -- it looks up
#! plasma/containmentactions/<plugin-id>. The Plasma 5 library name meant the
#! plugin was never found, so the containment had no actions and Latte's own
#! context-menu entries (Edit Dock, Layouts, ...) never appeared.
set_target_properties(plasma_containmentactions_lattecontextmenu PROPERTIES
    OUTPUT_NAME "org.kde.latte.contextmenu"
    PREFIX "")

target_link_libraries(plasma_containmentactions_lattecontextmenu
                        Qt::DBus
                        Qt::Widgets
                        KF6::I18n
                        KF6::XmlGui
                        Plasma::Plasma
                      )

install(TARGETS plasma_containmentactions_lattecontextmenu DESTINATION ${KDE_INSTALL_PLUGINDIR}/plasma/containmentactions)
