/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import org.kde.kirigami as Kirigami
import org.kde.latte.core 0.2 as LatteCore
import org.kde.plasma.components 3.0 as PlasmaComponents

//! Was a QtQuick.Controls 1 SpinBox with a custom SpinBoxStyle drawing the
//! arrows from the "widgets/arrows" SVG. Controls 1 and its styling system do
//! not exist in Qt6, and the Plasma 6 SpinBox is already themed.
//!
//! Note the Controls 2 API differs from the Controls 1 one this replaced:
//! `from`/`to` instead of `minimumValue`/`maximumValue`, and values are
//! integers. Nothing in Latte instantiates this component today.
PlasmaComponents.SpinBox {
    implicitWidth: LatteCore.Tools.mSize(Kirigami.Theme.defaultFont).width * 10
}
