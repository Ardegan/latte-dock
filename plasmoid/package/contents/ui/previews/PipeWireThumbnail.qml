/*
    SPDX-FileCopyrightText: 2020 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Window 2.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.pipewire as PipeWire
import org.kde.taskmanager 0.1 as TaskManager
import org.kde.kirigami as Kirigami

// opacity doesn't work in the root item
Item {
    anchors.fill: parent

    PipeWire.PipeWireSourceItem {
        id: pipeWireSourceItem

        //! Plasma 5's PipeWireSourceItem flipped `enabled` from C++ once the stream was
        //! up, and the opacity below rode on it. The Plasma 6 item does not touch
        //! `enabled` at all - it exposes `ready` instead - so `enabled` stayed false and
        //! the thumbnail was painted completely transparent even though the screencast
        //! was running and had a valid PipeWire nodeId. Keep the item non-interactive
        //! but drive opacity from `ready`.
        enabled: false
        visible: waylandItem.nodeId > 0
        nodeId: waylandItem.nodeId

        anchors.fill: parent

        opacity: ready ? 1 : 0

        TaskManager.ScreencastingRequest {
            id: waylandItem
            uuid: !windowsPreviewDlg.visible ? "" : thumbnailSourceItem.winId
        }

        /*Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }*/
    }
}
