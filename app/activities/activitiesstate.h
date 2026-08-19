/*
    SPDX-FileCopyrightText: 2026 Latte Dock Qt6 port
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef ACTIVITIESSTATE_H
#define ACTIVITIESSTATE_H

// Qt
#include <QHash>
#include <QObject>
#include <QString>
#include <QStringList>

namespace Latte {
namespace Activities {

//! Activity run states.
//!
//! Plasma 6 removed KActivities::Info::State from the client library
//! (plasma-activities), but kactivitymanagerd still reports the very same
//! numeric values over D-Bus, so these are kept bit-identical to the old
//! KF5 enum and can be compared against values coming off the wire.
enum State {
    Invalid = 0,  //!< this activity does not exist
    Running = 2,
    Starting = 3,
    Stopped = 4
};

//! Restores the activity run-state API that plasma-activities dropped in
//! Plasma 6, by talking to org.kde.ActivityManager directly.
//!
//! Only the *read* side can be restored. kactivitymanagerd 6.x exposes no
//! StartActivity/StopActivity methods any more (verified by introspecting the
//! whole session bus), and libPlasmaActivities exports no such symbols, so
//! activities can no longer be stopped at all on Plasma 6 — every existing
//! activity is permanently Running. Callers that used to stop an activity have
//! to degrade; see Synchronizer::pauseLayout().
//!
//! Implemented as a singleton rather than hanging off Latte::Corona because
//! several users (Latte::WindowSystem::AbstractWindowInterface among them)
//! have no Corona pointer at hand and used to build their own Consumer.
class Monitor : public QObject
{
    Q_OBJECT

public:
    static Monitor *self();

    //! run state of @p id, or Invalid when the activity is unknown
    State state(const QString &id) const;

    //! ids of all activities that are currently running
    QStringList runningActivities() const;

    //! true when the platform can stop activities at all. Always false on
    //! Plasma 6; kept as an explicit predicate so callers read intentionally
    //! rather than silently doing nothing.
    static bool canStopActivities();

Q_SIGNALS:
    void runningActivitiesChanged(const QStringList &runningActivities);

private Q_SLOTS:
    void reload();

private:
    explicit Monitor(QObject *parent = nullptr);

    void emitRunningIfChanged();

    QHash<QString, State> m_states;
    QStringList m_running;
};

}
}

#endif // ACTIVITIESSTATE_H
