/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "lattecontainmentplugin.h"

// local
#include "layoutmanager.h"
#include "types.h"

// Qt
#include <QtQml>

void LatteContainmentPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.latte.private.containment"));
    qmlRegisterUncreatableMetaObject(Latte::Containment::Types::staticMetaObject, uri, 0, 1, "Types", QStringLiteral("Latte Containment Types uncreatable"));
    qmlRegisterType<Latte::Containment::LayoutManager>(uri, 0, 1, "LayoutManager");
}

