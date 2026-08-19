/*
    SPDX-FileCopyrightText: 2026 Latte Dock Qt6 port
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "activitiesstate.h"

// Qt
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusPendingCall>
#include <QDebug>

namespace {

const char *ACTIVITIES_SERVICE = "org.kde.ActivityManager";
const char *ACTIVITIES_PATH = "/ActivityManager/Activities";
const char *ACTIVITIES_IFACE = "org.kde.ActivityManager.Activities";

//! Wire format of ListActivitiesWithInformation, "a(ssssi)".
//! Only @c id and @c state are consumed; the three middle strings are read
//! purely to advance the demarshaller, so their relative order is irrelevant
//! here and deliberately not relied upon.
struct ActivityInfoWire
{
    QString id;
    QString name;
    QString description;
    QString icon;
    int state = 0;
};

QDBusArgument &operator<<(QDBusArgument &arg, const ActivityInfoWire &info)
{
    arg.beginStructure();
    arg << info.id << info.name << info.description << info.icon << info.state;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, ActivityInfoWire &info)
{
    arg.beginStructure();
    arg >> info.id >> info.name >> info.description >> info.icon >> info.state;
    arg.endStructure();
    return arg;
}

}

Q_DECLARE_METATYPE(ActivityInfoWire)

namespace Latte {
namespace Activities {

Monitor *Monitor::self()
{
    //! function-local static rather than Q_GLOBAL_STATIC: the constructor is
    //! private, and only a member function may reach it.
    static Monitor instance;
    return &instance;
}

bool Monitor::canStopActivities()
{
    //! kactivitymanagerd 6.x exposes no StartActivity/StopActivity D-Bus
    //! methods and libPlasmaActivities exports no equivalent symbols.
    return false;
}

Monitor::Monitor(QObject *parent)
    : QObject(parent)
{
    qDBusRegisterMetaType<ActivityInfoWire>();
    qDBusRegisterMetaType<QList<ActivityInfoWire>>();

    auto bus = QDBusConnection::sessionBus();

    for (const auto &signalName : {"ActivityAdded", "ActivityRemoved", "ActivityStarted", "ActivityStopped"}) {
        bus.connect(QString::fromLatin1(ACTIVITIES_SERVICE),
                    QString::fromLatin1(ACTIVITIES_PATH),
                    QString::fromLatin1(ACTIVITIES_IFACE),
                    QString::fromLatin1(signalName),
                    this,
                    SLOT(reload()));
    }

    reload();
}

void Monitor::reload()
{
    QDBusMessage call = QDBusMessage::createMethodCall(QString::fromLatin1(ACTIVITIES_SERVICE),
                                                       QString::fromLatin1(ACTIVITIES_PATH),
                                                       QString::fromLatin1(ACTIVITIES_IFACE),
                                                       QStringLiteral("ListActivitiesWithInformation"));

    QDBusMessage reply = QDBusConnection::sessionBus().call(call, QDBus::Block, 2000);

    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        qWarning() << "Latte::Activities::Monitor: ListActivitiesWithInformation failed:" << reply.errorMessage();
        return;
    }

    QHash<QString, State> states;

    const auto arg = reply.arguments().first().value<QDBusArgument>();
    arg.beginArray();

    while (!arg.atEnd()) {
        ActivityInfoWire info;
        arg >> info;
        states.insert(info.id, static_cast<State>(info.state));
    }

    arg.endArray();

    m_states = states;
    emitRunningIfChanged();
}

void Monitor::emitRunningIfChanged()
{
    QStringList running;

    for (auto it = m_states.constBegin(); it != m_states.constEnd(); ++it) {
        if (it.value() == Running || it.value() == Starting) {
            running << it.key();
        }
    }

    running.sort();

    if (running == m_running) {
        return;
    }

    m_running = running;
    emit runningActivitiesChanged(m_running);
}

State Monitor::state(const QString &id) const
{
    return m_states.value(id, Invalid);
}

QStringList Monitor::runningActivities() const
{
    return m_running;
}

}
}
