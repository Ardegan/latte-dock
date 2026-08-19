add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_org.kde.latte.plasmoid\")

plasma_install_package(package org.kde.latte.plasmoid)

set(tasks_SRCS
    plugin/types.cpp
    plugin/lattetasksplugin.cpp
    #! vendored from plasma-desktop, see plugin/taskmanager/README.latte
    plugin/taskmanager/backend.cpp
    plugin/taskmanager/log_settings.cpp
    plugin/taskmanager/smartlauncherbackend.cpp
    plugin/taskmanager/smartlauncheritem.cpp
)

qt_add_library(lattetasksplugin SHARED ${tasks_SRCS})

kconfig_add_kcfg_files(lattetasksplugin plugin/taskmanager/kactivitymanagerd_plugins_settings.kcfgc)

target_include_directories(lattetasksplugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/plugin/taskmanager)

target_link_libraries(lattetasksplugin
                      Qt::Core
                      Qt::DBus
                      Qt::Gui
                      Qt::Qml
                      Qt::Quick
                      Qt::Widgets
                      KF6::ConfigCore
                      KF6::ConfigGui
                      KF6::CoreAddons
                      KF6::I18n
                      KF6::KIOFileWidgets
                      KF6::KIOGui
                      KF6::KIOWidgets
                      KF6::Notifications
                      KF6::Service
                      KF6::WindowSystem
                      Plasma::Activities
                      Plasma::ActivitiesStats
                      Plasma::Plasma
                      Plasma::PlasmaQuick
                      KSysGuard::ProcessCore
                      PW::LibNotificationManager)

install(TARGETS lattetasksplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/latte/private/tasks)
install(FILES plugin/qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/latte/private/tasks)
