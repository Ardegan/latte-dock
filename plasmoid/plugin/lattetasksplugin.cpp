/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "lattetasksplugin.h"

// local
#include "types.h"
#include "taskmanager/backend.h"
#include "taskmanager/smartlauncheritem.h"

// Qt
#include <QtQml>


void LatteTasksPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.latte.private.tasks"));
    qmlRegisterUncreatableType<Latte::Tasks::Types>(uri, 0, 1, "Types", "Latte Tasks Types uncreatable");

    //! Plasma 6 no longer ships org.kde.plasma.private.taskmanager as an
    //! importable QML module: the taskmanager applet registers these types
    //! into its own plugin (org.kde.plasma.taskmanager), embedded in a qrc
    //! inside plugins/plasma/applets/, which is unreachable from here.
    //! Latte therefore vendors the sources and registers them itself.
    qmlRegisterType<Backend>(uri, 0, 1, "Backend");
    qmlRegisterType<SmartLauncher::Item>(uri, 0, 1, "SmartLauncherItem");
}

