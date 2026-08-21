/*
    SPDX-FileCopyrightText: 2016 Smith AR <audoban@openmailbox.org>
    SPDX-FileCopyrightText: 2016 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.7
import QtQuick.Layouts 1.3
import Qt5Compat.GraphicalEffects

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.components 1.0 as LatteComponents

import org.kde.latte.private.tasks 0.1 as LatteTasks
import org.kde.kirigami as Kirigami

PlasmaComponents.Page {
    id: _tasksPage
    width: content.width + content.Layout.leftMargin * 2
    height: content.height + Kirigami.Units.smallSpacing * 2

    property bool disableAllWindowsFunctionality: tasks.Plasmoid.configuration.hideAllTasks

    readonly property bool isCurrentPage: (dialog.currentPage === _tasksPage)

    onIsCurrentPageChanged: {
        if (isCurrentPage && latteView.extendedInterface.latteTasksModel.count>1) {
            latteView.extendedInterface.appletRequestedVisualIndicator(tasks.Plasmoid.id);
        }
    }

    ColumnLayout {
        id: content

        width: (dialog.appliedWidth - Kirigami.Units.smallSpacing * 2) - Layout.leftMargin * 2
        spacing: dialog.subGroupSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        Layout.leftMargin: Kirigami.Units.smallSpacing * 2
        Layout.rightMargin: Kirigami.Units.smallSpacing * 2

        //! BEGIN: Appearance
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing

            LatteComponents.Header {
                text: i18n("Appearance")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Equalize icon sizes")
                    tooltip: i18n("Scale up icons that bake in their own transparent padding, so that all icons appear the same size")
                    value: tasks.Plasmoid.configuration.normalizeIconSizes

                    onClicked: {
                        tasks.Plasmoid.configuration.normalizeIconSizes = !tasks.Plasmoid.configuration.normalizeIconSizes;
                    }
                }
            }
        }
        //! END: Appearance

        //! BEGIN: Badges
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: dialog.advancedLevel

            LatteComponents.Header {
                text: i18n("Badges")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Notifications from tasks")
                    tooltip: i18n("Show unread messages or notifications from tasks")
                    value: tasks.Plasmoid.configuration.showInfoBadge

                    onClicked: {
                        tasks.Plasmoid.configuration.showInfoBadge = !tasks.Plasmoid.configuration.showInfoBadge;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Progress information for tasks")
                    tooltip: i18n("Show a progress animation for tasks e.g. when copying files with Dolphin")
                    value: tasks.Plasmoid.configuration.showProgressBadge

                    onClicked: {
                        tasks.Plasmoid.configuration.showProgressBadge = !tasks.Plasmoid.configuration.showProgressBadge;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Audio playing from tasks")
                    tooltip: i18n("Show audio playing from tasks")
                    value: tasks.Plasmoid.configuration.showAudioBadge

                    onClicked: {
                        tasks.Plasmoid.configuration.showAudioBadge = !tasks.Plasmoid.configuration.showAudioBadge;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Prominent color for notification badge")
                    enabled: tasks.Plasmoid.configuration.showInfoBadge
                    tooltip: i18n("Notification badge uses a more prominent background which is usually red")
                    value: tasks.Plasmoid.configuration.infoBadgeProminentColorEnabled

                    onClicked: {
                        tasks.Plasmoid.configuration.infoBadgeProminentColorEnabled = !tasks.Plasmoid.configuration.infoBadgeProminentColorEnabled;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Change volume when scrolling audio badge")
                    enabled: tasks.Plasmoid.configuration.showAudioBadge
                    tooltip: i18n("The user is able to mute/unmute with click or change the volume with mouse wheel")
                    value: tasks.Plasmoid.configuration.audioBadgeActionsEnabled

                    onClicked: {
                        tasks.Plasmoid.configuration.audioBadgeActionsEnabled = !tasks.Plasmoid.configuration.audioBadgeActionsEnabled;
                    }
                }
            }
        }
        //! END: Badges

        //! BEGIN: Tasks Interaction
        ColumnLayout {
            Layout.topMargin: dialog.basicLevel ? Kirigami.Units.smallSpacing : 0
            spacing: Kirigami.Units.smallSpacing

            LatteComponents.Header {
                text: i18n("Interaction")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Launchers are added only in current tasks applet")
                    tooltip: i18n("Launchers are added only in current tasks applet and not as regular applets or in any other applet")
                    value:tasks.Plasmoid.configuration.isPreferredForDroppedLaunchers

                    onClicked: {
                        tasks.Plasmoid.configuration.isPreferredForDroppedLaunchers = !tasks.Plasmoid.configuration.isPreferredForDroppedLaunchers;
                    }
                }

                LatteComponents.CheckBox {
                    id: windowActionsChk
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Window actions in the context menu")
                    visible: dialog.advancedLevel
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.showWindowActions

                    onClicked: {
                        tasks.Plasmoid.configuration.showWindowActions = !tasks.Plasmoid.configuration.showWindowActions;
                    }
                }

                LatteComponents.CheckBox {
                    id: previewPopupChk
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Preview window behaves as popup")
                    visible: dialog.advancedLevel
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.previewWindowAsPopup

                    onClicked: {
                        tasks.Plasmoid.configuration.previewWindowAsPopup = !tasks.Plasmoid.configuration.previewWindowAsPopup;
                    }
                }

                LatteComponents.CheckBox {
                    id: unifyGlobalShortcutsChk
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Based on position shortcuts apply only on current tasks")
                    // checked: tasks.Plasmoid.configuration.isPreferredForPositionShortcuts //! Disabled because it was not updated between multiple Tasks
                    tooltip: i18n("Based on position global shortcuts are enabled only for current tasks and not for other applets")
                    visible: dialog.advancedLevel
                    enabled: latteView.isPreferredForShortcuts || (!latteView.layout.preferredForShortcutsTouched && latteView.isHighestPriorityView())
                    value: tasks.Plasmoid.configuration.isPreferredForPositionShortcuts

                    onClicked: {
                        tasks.Plasmoid.configuration.isPreferredForPositionShortcuts = !tasks.Plasmoid.configuration.isPreferredForPositionShortcuts;
                    }
                }
            }
        }
        //! END: Tasks Interaction

        //! BEGIN: Tasks Filters
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing


            LatteComponents.Header {
                text: i18n("Filters")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only tasks from the current screen")
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.showOnlyCurrentScreen

                    onClicked: {
                        tasks.Plasmoid.configuration.showOnlyCurrentScreen = !tasks.Plasmoid.configuration.showOnlyCurrentScreen;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only tasks from the current desktop")
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.showOnlyCurrentDesktop

                    onClicked: {
                        tasks.Plasmoid.configuration.showOnlyCurrentDesktop = !tasks.Plasmoid.configuration.showOnlyCurrentDesktop;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only tasks from the current activity")
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.showOnlyCurrentActivity

                    onClicked: {
                        tasks.Plasmoid.configuration.showOnlyCurrentActivity = !tasks.Plasmoid.configuration.showOnlyCurrentActivity;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only tasks from launchers")
                    visible: dialog.advancedLevel
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.showWindowsOnlyFromLaunchers

                    onClicked: {
                        tasks.Plasmoid.configuration.showWindowsOnlyFromLaunchers = !tasks.Plasmoid.configuration.showWindowsOnlyFromLaunchers;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only launchers and hide all tasks")
                    tooltip: i18n("Tasks become hidden and only launchers are shown")
                    visible: dialog.advancedLevel
                    value: tasks.Plasmoid.configuration.hideAllTasks

                    onClicked: {
                        tasks.Plasmoid.configuration.hideAllTasks = !tasks.Plasmoid.configuration.hideAllTasks;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Show only grouped tasks for same application")
                    tooltip: i18n("By default group tasks of the same application")
                    visible: dialog.advancedLevel
                    enabled: !disableAllWindowsFunctionality
                    value: tasks.Plasmoid.configuration.groupTasksByDefault

                    onClicked: {
                        tasks.Plasmoid.configuration.groupTasksByDefault = !tasks.Plasmoid.configuration.groupTasksByDefault;
                    }
                }
            }
        }

        //! END: Tasks Filters

        //! BEGIN: Animations
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            enabled: plasmoid.configuration.animationsEnabled
            visible: dialog.advancedLevel

            LatteComponents.Header {
                text: i18n("Animations")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Bounce launchers when triggered")
                    value: tasks.Plasmoid.configuration.animationLauncherBouncing
                    enabled: !latteView.indicator.info.providesTaskLauncherAnimation

                    onClicked: {
                        tasks.Plasmoid.configuration.animationLauncherBouncing = !tasks.Plasmoid.configuration.animationLauncherBouncing;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Bounce tasks that need attention")
                    value: tasks.Plasmoid.configuration.animationWindowInAttention
                    enabled: !latteView.indicator.info.providesInAttentionAnimation

                    onClicked: {
                        tasks.Plasmoid.configuration.animationWindowInAttention = !tasks.Plasmoid.configuration.animationWindowInAttention;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Slide in and out single windows")
                    value: tasks.Plasmoid.configuration.animationNewWindowSliding

                    onClicked: {
                        tasks.Plasmoid.configuration.animationNewWindowSliding = !tasks.Plasmoid.configuration.animationNewWindowSliding;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Grouped tasks bounce their new windows")
                    value: tasks.Plasmoid.configuration.animationWindowAddedInGroup
                    enabled: !latteView.indicator.info.providesGroupedWindowAddedAnimation

                    onClicked: {
                        tasks.Plasmoid.configuration.animationWindowAddedInGroup = !tasks.Plasmoid.configuration.animationWindowAddedInGroup;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Grouped tasks slide out their closed windows")
                    value: tasks.Plasmoid.configuration.animationWindowRemovedFromGroup
                    enabled: !latteView.indicator.info.providesGroupedWindowRemovedAnimation

                    onClicked: {
                        tasks.Plasmoid.configuration.animationWindowRemovedFromGroup = !tasks.Plasmoid.configuration.animationWindowRemovedFromGroup;
                    }
                }
            }
        }
        //! END: Animations


        //! BEGIN: Launchers Group
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing


            LatteComponents.Header {
                text: i18n("Launchers")
            }

            ColumnLayout {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 2

                    property int group: tasks.Plasmoid.configuration.launchersGroup

                    readonly property int buttonsCount: layoutGroupButton.visible ? 3 : 2
                    readonly property int buttonSize: (dialog.optionsWidth - (spacing * buttonsCount-1)) / buttonsCount


                    PlasmaComponents.Button {
                        Layout.minimumWidth: parent.buttonSize
                        Layout.maximumWidth: Layout.minimumWidth
                        text: i18nc("unique launchers group","Unique Group")
                        checked: parent.group === group
                        checkable: false
                        PlasmaComponents.ToolTip.text: i18n("Use a unique set of launchers for this view which is independent from any other view")
                        PlasmaComponents.ToolTip.visible: hovered && PlasmaComponents.ToolTip.text !== ""

                        readonly property int group: LatteCore.Types.UniqueLaunchers

                        onPressedChanged: {
                            if (pressed) {
                                tasks.Plasmoid.configuration.launchersGroup = group;
                            }
                        }
                    }

                    PlasmaComponents.Button {
                        id: layoutGroupButton
                        Layout.minimumWidth: parent.buttonSize
                        Layout.maximumWidth: Layout.minimumWidth
                        text: i18nc("layout launchers group","Layout Group")
                        checked: parent.group === group
                        checkable: false
                        PlasmaComponents.ToolTip.text: i18n("Use the current layout set of launchers for this latteView. This group provides launchers <b>synchronization</b> between different views in the <b>same layout</b>")
                        PlasmaComponents.ToolTip.visible: hovered && PlasmaComponents.ToolTip.text !== ""
                        //! it is shown only when the user has activated that option manually from the text layout file
                        visible: tasks.Plasmoid.configuration.launchersGroup === group

                        readonly property int group: LatteCore.Types.LayoutLaunchers

                        onPressedChanged: {
                            if (pressed) {
                                tasks.Plasmoid.configuration.launchersGroup = group;
                            }
                        }
                    }

                    PlasmaComponents.Button {
                        Layout.minimumWidth: parent.buttonSize
                        Layout.maximumWidth: Layout.minimumWidth
                        text: i18nc("global launchers group","Global Group")
                        checked: parent.group === group
                        checkable: false
                        PlasmaComponents.ToolTip.text: i18n("Use the global set of launchers for this latteView. This group provides launchers <b>synchronization</b> between different views and between <b>different layouts</b>")
                        PlasmaComponents.ToolTip.visible: hovered && PlasmaComponents.ToolTip.text !== ""

                        readonly property int group: LatteCore.Types.GlobalLaunchers

                        onPressedChanged: {
                            if (pressed) {
                                tasks.Plasmoid.configuration.launchersGroup = group;
                            }
                        }
                    }
                }
            }
        }
        //! END: Launchers Group

        //! BEGIN: Scrolling
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            visible: dialog.advancedLevel

            LatteComponents.HeaderSwitch {
                id: scrollingHeader
                Layout.minimumWidth: dialog.optionsWidth + 2 *Kirigami.Units.smallSpacing
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: implicitHeight
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                enabled: LatteCore.WindowSystem.compositingActive

                checked: tasks.Plasmoid.configuration.scrollTasksEnabled
                text: i18n("Scrolling")
                tooltip: i18n("Enable tasks scrolling when they overflow and exceed the available space");

                onPressed: {
                    tasks.Plasmoid.configuration.scrollTasksEnabled = !tasks.Plasmoid.configuration.scrollTasksEnabled;;
                }
            }

            ColumnLayout {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2
                spacing: 0
                enabled: scrollingHeader.checked

                GridLayout {
                    columns: 2
                    Layout.minimumWidth: dialog.optionsWidth
                    Layout.maximumWidth: Layout.minimumWidth

                    Layout.topMargin: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: i18n("Manual")
                    }

                    LatteComponents.ComboBox {
                        id: manualScrolling
                        Layout.minimumWidth: leftClickAction.width
                        Layout.maximumWidth: leftClickAction.width
                        model: [i18nc("disabled manual scrolling", "Disabled scrolling"),
                            dialog.panelIsVertical ? i18n("Only vertical scrolling") : i18n("Only horizontal scrolling"),
                            i18n("Horizontal and vertical scrolling")]

                        currentIndex: tasks.Plasmoid.configuration.manualScrollTasksType
                        onCurrentIndexChanged: tasks.Plasmoid.configuration.manualScrollTasksType = currentIndex;
                    }

                    PlasmaComponents.Label {
                        id: autoScrollText
                        Layout.fillWidth: true
                        text: i18n("Automatic")
                    }

                    LatteComponents.ComboBox {
                        id: autoScrolling
                        Layout.minimumWidth: leftClickAction.width
                        Layout.maximumWidth: leftClickAction.width
                        model: [
                            i18n("Disabled"),
                            i18n("Enabled")
                        ]

                        currentIndex: tasks.Plasmoid.configuration.autoScrollTasksEnabled
                        onCurrentIndexChanged: {
                            if (currentIndex === 0) {
                                tasks.Plasmoid.configuration.autoScrollTasksEnabled = false;
                            } else {
                                tasks.Plasmoid.configuration.autoScrollTasksEnabled = true;
                            }
                        }
                    }
                }
            }
        }
        //! END: Scrolling


        //! BEGIN: Actions
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            visible: dialog.advancedLevel

            LatteComponents.Header {
                text: i18n("Actions")
            }

            ColumnLayout {
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2
                spacing: 0

                GridLayout {
                    columns: 2
                    Layout.minimumWidth: dialog.optionsWidth
                    Layout.maximumWidth: Layout.minimumWidth

                    Layout.topMargin: Kirigami.Units.smallSpacing
                    enabled: !disableAllWindowsFunctionality

                    PlasmaComponents.Label {
                        id: leftClickLbl
                        text: i18n("Left Click")
                    }

                    LatteComponents.ComboBox {
                        id: leftClickAction
                        Layout.fillWidth: true
                        model: [i18nc("present windows action", "Present Windows"),
                            i18n("Cycle Through Tasks"),
                            i18n("Preview Windows")]

                        currentIndex: {
                            switch(tasks.Plasmoid.configuration.leftClickAction) {
                            case LatteTasks.Types.PresentWindows:
                                return 0;
                            case LatteTasks.Types.CycleThroughTasks:
                                return 1;
                            case LatteTasks.Types.PreviewWindows:
                                return 2;
                            }

                            return 0;
                        }

                        onCurrentIndexChanged: {
                            switch(currentIndex) {
                            case 0:
                                tasks.Plasmoid.configuration.leftClickAction = LatteTasks.Types.PresentWindows;
                                break;
                            case 1:
                                tasks.Plasmoid.configuration.leftClickAction = LatteTasks.Types.CycleThroughTasks;
                                break;
                            case 2:
                                tasks.Plasmoid.configuration.leftClickAction = LatteTasks.Types.PreviewWindows;
                                break;
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        id: middleClickText
                        text: i18n("Middle Click")
                    }

                    LatteComponents.ComboBox {
                        id: middleClickAction
                        Layout.fillWidth: true
                        model: [
                            i18nc("The click action", "None"),
                            i18n("Close Window or Group"),
                            i18n("New Instance"),
                            i18n("Minimize/Restore Window or Group"),
                            i18n("Cycle Through Tasks"),
                            i18n("Toggle Task Grouping")
                        ]

                        currentIndex: tasks.Plasmoid.configuration.middleClickAction
                        onCurrentIndexChanged: tasks.Plasmoid.configuration.middleClickAction = currentIndex
                    }

                    PlasmaComponents.Label {
                        text: i18n("Hover")
                    }

                    LatteComponents.ComboBox {
                        id: hoverAction
                        Layout.fillWidth: true
                        model: [
                            i18nc("none action", "None"),
                            i18n("Preview Windows"),
                            i18n("Highlight Windows"),
                            i18n("Preview and Highlight Windows"),
                        ]

                        currentIndex: {
                            switch(tasks.Plasmoid.configuration.hoverAction) {
                            case LatteTasks.Types.NoneAction:
                                return 0;
                            case LatteTasks.Types.PreviewWindows:
                                return 1;
                            case LatteTasks.Types.HighlightWindows:
                                return 2;
                            case LatteTasks.Types.PreviewAndHighlightWindows:
                                return 3;
                            }

                            return 0;
                        }

                        onCurrentIndexChanged: {
                            switch(currentIndex) {
                            case 0:
                                tasks.Plasmoid.configuration.hoverAction = LatteTasks.Types.NoneAction;
                                break;
                            case 1:
                                tasks.Plasmoid.configuration.hoverAction = LatteTasks.Types.PreviewWindows;
                                break;
                            case 2:
                                tasks.Plasmoid.configuration.hoverAction = LatteTasks.Types.HighlightWindows;
                                break;
                            case 3:
                                tasks.Plasmoid.configuration.hoverAction = LatteTasks.Types.PreviewAndHighlightWindows;
                                break;
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        text: i18n("Wheel")
                    }

                    LatteComponents.ComboBox {
                        id: wheelAction
                        Layout.fillWidth: true
                        model: [
                            i18nc("none action", "None"),
                            i18n("Cycle Through Tasks"),
                            i18n("Cycle And Minimize Tasks")
                        ]

                        currentIndex: tasks.Plasmoid.configuration.taskScrollAction
                        onCurrentIndexChanged: tasks.Plasmoid.configuration.taskScrollAction = currentIndex
                    }

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        enabled: !disableAllWindowsFunctionality

                        Layout.minimumWidth: middleClickText.width
                        Layout.maximumWidth: middleClickText.width

                        LatteComponents.ComboBox {
                            id: modifier
                            Layout.fillWidth: true
                            model: ["Shift", "Ctrl", "Alt", "Meta"]

                            currentIndex: tasks.Plasmoid.configuration.modifier
                            onCurrentIndexChanged: tasks.Plasmoid.configuration.modifier = currentIndex
                        }

                        PlasmaComponents.Label {
                            text: "+"
                        }
                    }

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        enabled: !disableAllWindowsFunctionality

                        readonly property int maxSize: 0.4 * dialog.optionsWidth

                        LatteComponents.ComboBox {
                            id: modifierClick
                            Layout.preferredWidth: 0.7 * parent.maxSize
                            Layout.maximumWidth: parent.maxSize
                            model: [i18n("Left Click"), i18n("Middle Click"), i18n("Right Click")]

                            currentIndex: tasks.Plasmoid.configuration.modifierClick
                            onCurrentIndexChanged: tasks.Plasmoid.configuration.modifierClick = currentIndex
                        }

                        PlasmaComponents.Label {
                            text: "="
                        }

                        LatteComponents.ComboBox {
                            id: modifierClickAction
                            Layout.fillWidth: true
                            model: [i18nc("The click action", "None"), i18n("Close Window or Group"),
                                i18n("New Instance"), i18n("Minimize/Restore Window or Group"),  i18n("Cycle Through Tasks"), i18n("Toggle Task Grouping")]

                            currentIndex: tasks.Plasmoid.configuration.modifierClickAction
                            onCurrentIndexChanged: tasks.Plasmoid.configuration.modifierClickAction = currentIndex
                        }
                    }
                }

                RowLayout {
                    Layout.minimumWidth: dialog.optionsWidth
                    Layout.maximumWidth: Layout.minimumWidth
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing
                    enabled: !disableAllWindowsFunctionality

                }
            }
        }
        //! END: Actions

        //! BEGIN: Recycling
       /* ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            visible: dialog.advancedLevel

            LatteComponents.Header {
                text: i18n("Recycling")
            }

            PlasmaComponents.Button {
                Layout.minimumWidth: dialog.optionsWidth
                Layout.maximumWidth: Layout.minimumWidth
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2
                Layout.topMargin: Kirigami.Units.smallSpacing

                text: i18n("Remove Latte Tasks Applet")
                enabled: latteView.latteTasksArePresent
                PlasmaComponents.ToolTip.text: i18n("Remove Latte Tasks plasmoid")
                PlasmaComponents.ToolTip.visible: hovered && PlasmaComponents.ToolTip.text !== ""

                onClicked: {
                    latteView.removeTasksPlasmoid();
                }
            }
        }*/
    }
}
