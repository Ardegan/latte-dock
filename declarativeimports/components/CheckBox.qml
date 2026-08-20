/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.CheckBox {
    property int value: 0

    //! Controls 1 controls carried a `tooltip` property; Controls 2 replaced it
    //! with the attached ToolTip. Kept as a property here because ~22 call
    //! sites across the configuration pages set it.
    property string tooltip: ""

    PlasmaComponents.ToolTip.text: tooltip
    PlasmaComponents.ToolTip.visible: hovered && tooltip !== ""

    //! Controls 1 CheckBox had `partiallyCheckedEnabled`/`checkedState`; the
    //! Controls 2 equivalents are `tristate`/`checkState`. The old names silently
    //! threw a ReferenceError here, so `checked` was never assigned either.
    onValueChanged: {
        if (tristate) {
            checkState = value;
        } else {
            checked = value;
        }
    }
}

