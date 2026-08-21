/*
    SPDX-FileCopyrightText: 2016 Smith AR <audoban@openmailbox.org>
    SPDX-FileCopyrightText: 2016 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.7
import QtQuick.Layouts 1.3
import Qt5Compat.GraphicalEffects
import QtQuick.Window 2.2

import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.kquickcontrolsaddons 2.0 as KQuickControlAddons

import org.kde.latte.core 0.2 as LatteCore

import "../controls" as LatteExtraControls
import org.kde.kirigami as Kirigami

Loader {
    active: plasmoid && plasmoid.configuration && latteView

    sourceComponent: FocusScope {
        id: dialog

        //! See LatteDockConfiguration.qml: this is a plain QQuickView, so Kirigami
        //! resolves colours from the application scheme while the Plasma Components
        //! inside draw KSvg backgrounds from the Plasma desktop theme. Pin Kirigami to
        //! the Plasma theme so a dark theme with a light colour scheme does not end up
        //! painting dark text on dark buttons.
        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: themeExtended ? themeExtended.defaultTheme.textColor : Kirigami.Theme.textColor
        Kirigami.Theme.backgroundColor: themeExtended ? themeExtended.defaultTheme.backgroundColor : Kirigami.Theme.backgroundColor

        width: typeSettings.width + Kirigami.Units.smallSpacing * 4
        height: typeSettings.height + Kirigami.Units.smallSpacing * 4
        Layout.minimumWidth: width
        Layout.minimumHeight: height
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        property bool panelIsVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

        KSvg.FrameSvgItem{
            id: backgroundFrameSvgItem
            anchors.fill: parent
            imagePath: "dialogs/background"
            enabledBorders: viewConfig.enabledBorders

            onEnabledBordersChanged: viewConfig.updateEffects()
            Component.onCompleted: viewConfig.updateEffects()
        }

        LatteExtraControls.TypeSelection{
            id: typeSettings
            anchors.centerIn: parent

            Component.onCompleted: forceActiveFocus();

            Keys.onPressed: {
                if (event.key === Qt.Key_Escape) {
                    primaryConfigView.hideConfigWindow();
                }
            }
        }
    }
}
