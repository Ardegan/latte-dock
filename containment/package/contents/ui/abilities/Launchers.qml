/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.7
import org.kde.plasma.plasmoid 2.0

import "./privates" as Ability

Ability.LaunchersPrivate {
    //! do not update during dragging/moving applets inConfigureAppletsMode
    updateIsBlocked: (root.dragOverlay && root.dragOverlay.pressed)
                     || layouter.appletsInParentChange

    readonly property bool isReady: latteView && latteView.layout && universalSettings && root.layoutsManager !== null
    readonly property bool isCapableOfLayoutLaunchers: latteView && latteView.layout
    readonly property bool isCapableOfUniversalLaunchers: latteView && universalSettings

    property string layoutName: ""

    readonly property var layoutLaunchers: latteView && latteView.layout ? latteView.layout.launchers : []
    readonly property var universalLaunchers: latteView && universalSettings ? universalSettings.launchers : []

    function addAbilityClient(client) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.addAbilityClient(client);
    }

    function removeAbilityClient(client) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.removeAbilityClient(client);
    }

    function addSyncedLauncher(senderId, group, groupId, launcherUrl) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.addLauncher(layoutName,
                                                   senderId,
                                                   group,
                                                   groupId,
                                                   launcherUrl);
    }

    function removeSyncedLauncher(senderId, group,groupId, launcherUrl) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.removeLauncher(layoutName,
                                                      senderId,
                                                      group,
                                                      groupId,
                                                      launcherUrl);
    }

    function addSyncedLauncherToActivity(senderId, group, groupId, launcherUrl, activityId) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.addLauncherToActivity(layoutName,
                                                             senderId,
                                                             group,
                                                             groupId,
                                                             launcherUrl,
                                                             activityId);
    }

    function removeSyncedLauncherFromActivity(senderId, group, groupId, launcherUrl, activityId) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.removeLauncherFromActivity(layoutName,
                                                                  senderId,
                                                                  group,
                                                                  groupId,
                                                                  launcherUrl,
                                                                  activityId);
    }

    function addDroppedLaunchers(senderId, group, groupId, urls) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.urlsDropped(layoutName,
                                                   senderId,
                                                   group,
                                                   groupId,
                                                   urls);
    }

    function validateSyncedLaunchersOrder(senderId, group, groupId, orderedlaunchers) {
        if (!layoutsManager) {
            //! Plasma 6 builds the containment QML before View::init() publishes
            //! _latte_layoutsManager_object. Clients re-register themselves when
            //! `isReady` turns true, so dropping the early call is safe.
            return;
        }

        layoutsManager.syncedLaunchers.validateLaunchersOrder(layoutName,
                                                              senderId,
                                                              group,
                                                              groupId,
                                                              orderedlaunchers);
    }

    function addDroppedLaunchersInStealingApplet(launchers) {
        if (hasStealingApplet) {
            appletStealingDroppedLaunchers.addDroppedLaunchers(launchers);
        }
    }

    function showAddLaunchersMessageInStealingApplet() {
        if (hasStealingApplet) {
            appletStealingDroppedLaunchers.isShowingAddLaunchersMessage = true;
        }
    }

    function hideAddLaunchersMessageInStealingApplet() {
        if (hasStealingApplet) {
            appletStealingDroppedLaunchers.isShowingAddLaunchersMessage = false;
        }
    }

    function setLayoutLaunchers(launchers) {
        if (isCapableOfLayoutLaunchers) {
            latteView.layout.launchers = launchers;
        }
    }

    function setUniversalLaunchers(launchers) {
        if (isCapableOfUniversalLaunchers) {
            universalSettings.launchers = launchers;
        }
    }
}
