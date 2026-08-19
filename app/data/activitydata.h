/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later

*/

#ifndef ACTIVITYDATA_H
#define ACTIVITYDATA_H

//! local
#include "genericdata.h"
#include "generictable.h"

//! Qt
#include <QMetaType>
#include <QIcon>
#include <QString>

//! local
#include "../activities/activitiesstate.h"

namespace Latte {
namespace Data {

class Activity : public Generic
{
public:
    Activity();
    Activity(Activity &&o);
    Activity(const Activity &o);

    //! Layout data
    bool isCurrent{false};
    QString icon;
    Latte::Activities::State state{Latte::Activities::Invalid};

    bool isValid() const;
    bool isRunning() const;

    //! Operators
    Activity &operator=(const Activity &rhs);
    Activity &operator=(Activity &&rhs);
};

//! This is an Activities map in the following structure:
//! #activityId -> activite_information
typedef GenericTable<Data::Activity> ActivitiesTable;

}
}

Q_DECLARE_METATYPE(Latte::Data::Activity)
Q_DECLARE_METATYPE(Latte::Data::ActivitiesTable)

#endif
