/*
    SPDX-FileCopyrightText: 2013-2016 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KConfigWatcher>
#include <QUrl>
#include <QVariantMap>

#include <QObject>
#include <QRect>

#include <netwm.h>
#include <qwindowdefs.h>

#include "kactivitymanagerd_plugins_settings.h"

class QAction;
class QActionGroup;
class QQuickItem;
class QQuickWindow;
class QJsonArray;

namespace KActivities
{
class Consumer;
}

class Backend : public QObject
{
    Q_OBJECT

    //! Restored for Latte. Plasma 6 moved window highlighting and the window
    //! view out of Backend and into the applet's own QML (via org.kde.dbus).
    //! Latte keeps them here so its QML keeps calling backend.<x>() unchanged.
    Q_PROPERTY(bool highlightWindows READ highlightWindows WRITE setHighlightWindows NOTIFY highlightWindowsChanged)
    Q_PROPERTY(bool windowViewAvailable READ windowViewAvailable NOTIFY windowViewAvailableChanged)

public:
    enum MiddleClickAction {
        None = 0,
        Close,
        NewInstance,
        ToggleMinimized,
        ToggleGrouping,
        BringToCurrentDesktop,
    };

    Q_ENUM(MiddleClickAction)

    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;

    Q_INVOKABLE QVariantList jumpListActions(const QUrl &launcherUrl, QObject *parent);
    Q_INVOKABLE QVariantList placesActions(const QUrl &launcherUrl, bool showAllPlaces, QObject *parent);
    Q_INVOKABLE QVariantList recentDocumentActions(const QUrl &launcherUrl, QObject *parent);
    Q_INVOKABLE void setActionGroup(QAction *action) const;

    Q_INVOKABLE QRect globalRect(QQuickItem *item) const;

    Q_INVOKABLE bool isApplication(const QUrl &url) const;

    Q_INVOKABLE qint64 parentPid(qint64 pid) const;

    bool highlightWindows() const;
    void setHighlightWindows(bool highlight);

    bool windowViewAvailable() const;

    //! Restored from Plasma 5; dropped from the Plasma 6 Backend but still
    //! needed by Latte's drag handling and drop target.
    Q_INVOKABLE QVariantMap generateMimeData(const QString &mimeType, const QVariant &mimeData, const QUrl &url) const;
    Q_INVOKABLE QList<QUrl> jsonArrayToUrlList(const QJsonArray &array) const;

    //! KWin D-Bus calls, mirroring what the Plasma 6 applet now does in QML.
    Q_INVOKABLE void windowsHovered(const QVariant &winIds, bool hovered);
    Q_INVOKABLE void cancelHighlightWindows();
    Q_INVOKABLE void activateWindowView(const QVariant &winIds);

    Q_INVOKABLE static QUrl tryDecodeApplicationsUrl(const QUrl &launcherUrl);
    Q_INVOKABLE static QStringList applicationCategories(const QUrl &launcherUrl);

Q_SIGNALS:
    void addLauncher(const QUrl &url) const;

    void showAllPlaces();

    void highlightWindowsChanged();
    void windowViewAvailableChanged();

private Q_SLOTS:
    void handleRecentDocumentAction() const;

private:
    QVariantList systemSettingsActions(QObject *parent) const;

    QStringList windowIdsFrom(const QVariant &winIds) const;

    bool m_highlightWindows = false;
    bool m_windowViewAvailable = false;

    QActionGroup *m_actionGroup = nullptr;
    KActivities::Consumer *m_activitiesConsumer = nullptr;

    KActivityManagerdPluginsSettings m_activityManagerPluginsSettings;
    KConfigWatcher::Ptr m_activityManagerPluginsSettingsWatcher;
};
