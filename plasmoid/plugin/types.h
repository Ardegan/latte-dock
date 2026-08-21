/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef LATTETASKSTYPES_H
#define LATTETASKSTYPES_H

// Qt
#include <QObject>
#include <QMetaEnum>
#include <QMetaType>

namespace Latte {
namespace Tasks {

//! Q_GADGET makes this a QML *value type*, whose name must start lowercase in Qt6, so
//! registering it as "Types" logged `Invalid QML element name "Types"`. A Q_NAMESPACE is
//! not a value type, and enum scoping is identical, so nothing else changes.
namespace Types
{
Q_NAMESPACE

    enum Modifier
    {
        Shift = 0,
        Ctrl,
        Alt,
        Meta
    };
    Q_ENUM_NS(Modifier);

    enum ClickAction
    {
        LeftClick = 0,
        MiddleClick,
        RightClick
    };
    Q_ENUM_NS(ClickAction);

    enum TaskAction
    {
        NoneAction = 0,
        Close,
        NewInstance,
        ToggleMinimized,
        CycleThroughTasks,
        ToggleGrouping,
        PresentWindows,
        PreviewWindows,
        HighlightWindows,
        PreviewAndHighlightWindows
    };
    Q_ENUM_NS(TaskAction);

    enum TaskScrollAction
    {
        ScrollNone = 0,
        ScrollTasks,
        ScrollToggleMinimized
    };
    Q_ENUM_NS(TaskScrollAction);

    enum ManualScrollType
    {
        ManualScrollDisabled = 0,
        ManualScrollOnlyParallel,
        ManualScrollVerticalHorizontal
    };
    Q_ENUM_NS(ManualScrollType);
}

}
}

#endif
