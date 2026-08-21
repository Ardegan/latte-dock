/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef LATTECONTAINMENTTYPES_H
#define LATTECONTAINMENTTYPES_H

// Qt
#include <QObject>
#include <QMetaEnum>
#include <QMetaType>

namespace Latte {
namespace Containment {

//! Q_GADGET makes this a QML *value type*, whose name must start lowercase in Qt6, so
//! registering it as "Types" logged `Invalid QML element name "Types"`. A Q_NAMESPACE is
//! not a value type, and enum scoping is identical, so nothing else changes.
namespace Types
{
Q_NAMESPACE

    enum ScrollAction
    {
        ScrollNone = 0,
        ScrollDesktops,
        ScrollActivities,
        ScrollTasks,
        ScrollToggleMinimized
    };
    Q_ENUM_NS(ScrollAction);

    enum ShadowColorGroup
    {
        DefaultColorShadow = 0,
        ThemeColorShadow,
        UserColorShadow
    };
    Q_ENUM_NS(ShadowColorGroup);

    enum ThemeColorsGroup
    {
        PlasmaThemeColors = 0,
        ReverseThemeColors,
        SmartThemeColors,
        DarkThemeColors,
        LightThemeColors,
        LayoutThemeColors
    };
    Q_ENUM_NS(ThemeColorsGroup);

    enum WindowColorsGroup
    {
        NoneWindowColors = 0,
        ActiveWindowColors,
        TouchingWindowColors
    };
    Q_ENUM_NS(WindowColorsGroup);

    enum ActiveWindowFilterGroup
    {
        ActiveInCurrentScreen = 0,
        ActiveFromAllScreens
    };
    Q_ENUM_NS(ActiveWindowFilterGroup);
}

}
}

#endif
