/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects
import QtQml.Models 2.2

import org.kde.draganddrop 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons

import org.kde.taskmanager 0.1 as TaskManager
import org.kde.kirigami as Kirigami
import org.kde.latte.core 0.2 as LatteCore

PlasmaComponents.ScrollView {
    id: mainToolTip
    property Item parentTask: null
    property var rootIndex: []

    property string appName
    property int pidParent
    property bool isGroup
    property bool hideCloseButtons

    property var windows: []
    readonly property bool isWin: windows !== undefined

    property variant icon
    property url launcherUrl
    property bool isLauncher
    property bool isMinimizedParent

    // Needed for generateSubtext()
    property string displayParent
    property string genericName
    property var virtualDesktopParent
    property bool isOnAllVirtualDesktopsParent
    property var activitiesParent
    //
    readonly property bool isVerticalPanel: plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: contentItem.width
    Layout.maximumWidth: Layout.minimumWidth

    Layout.minimumHeight: contentItem.height
    Layout.maximumHeight: Layout.minimumHeight

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int textWidth: LatteCore.Tools.mSize(Kirigami.Theme.defaultFont).width * 20

    //! Controls 2 ScrollView: the scrollbars are attached properties, the
    //! Flickable is `contentItem`, and the old `viewport` is the available area.
    QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    //! ScrollView builds its Flickable lazily, so contentItem is not one yet at
    //! Component.onCompleted; bind declaratively once it exists instead.
    Binding {
        //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
        target: mainToolTip.contentItem
        property: "interactive"
        when: mainToolTip.contentItem instanceof Flickable
        value: isVerticalPanel ? mainToolTip.contentHeight > mainToolTip.availableHeight
                               : mainToolTip.contentWidth > mainToolTip.availableWidth
    }

    Item{
        width: contentItem.width
        height: contentItem.height

        //! DropArea
        DropArea {
            id: dropMainArea
            anchors.fill: parent
            enabled: isGroup
            preventStealing: true

            property QtObject currentWindow

            onDragLeave: {
                windowsPreviewDlg.hide(9.9);
            }

            onDragMove: {
                var current = mainToolTip.instanceAtPos(event.x, event.y);

                if (current && currentWindow !== current && current.submodelIndex) {
                    currentWindow = current;
                    tasksModel.requestActivate(current.submodelIndex);
                }
            }
        } //! DropArea

        Loader {
            id: contentItem
            active: !isLauncher
            sourceComponent: Grid {
                rows: !isVerticalPanel
                columns: isVerticalPanel
                flow: isVerticalPanel ? Grid.TopToBottom : Grid.LeftToRight
                spacing: Kirigami.Units.largeSpacing

                readonly property bool hasVisibleDescription: {
                    for (var i=0; i<children.length; ++i) {
                        var child = children[i];

                        if (child && child.descriptionIsVisible) {
                            return true;
                        }
                    }

                    return false;
                }

                Repeater {
                    id: groupRepeater
                    model: DelegateModel {
                        model: isGroup ? tasksModel : 1
                        rootIndex: mainToolTip.rootIndex

                        delegate: ToolTipInstance {
                            submodelIndex: isGroup ? tasksModel.makeModelIndex(mainToolTip.rootIndex.row, index) : mainToolTip.rootIndex
                        }
                    }
                }
            }
        } //! Loader
    } //! Item

    function instanceAtPos(x, y){
        var previewInstances = isGroup ? contentItem.children[0].children : contentItem.children;
        var instancesLength = previewInstances.length;

        for(var i=0; i<instancesLength; ++i){
            var instance = previewInstances[i];
            var choords = contentItem.mapFromItem(instance,0, 0);

            if(choords.y < 0)
                choords.y = 0;
            if(choords.x < 0)
                choords.x = 0;

            if( (x>=choords.x) && (x<=choords.x+instance.width)
                    && (y>=choords.y) && (y<=choords.y+instance.height)){
                return instance;
            }
        }
        return null;
    }
}


