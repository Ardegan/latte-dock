/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef LATTECORETOOLS_H
#define LATTECORETOOLS_H

// Qt
#include <QObject>
#include <QColor>
#include <QFont>
#include <QQmlEngine>
#include <QJSEngine>
#include <QSizeF>


namespace Latte{

class Tools final: public QObject
{
    Q_OBJECT

public:
    explicit Tools(QObject *parent = nullptr);

public slots:
    Q_INVOKABLE float colorBrightness(QColor color);
    Q_INVOKABLE float colorLumina(QColor color);

    //! Size of the letter "M" in @p font, as Plasma::Theme::mSize() used to
    //! provide. Plasma 6 removed the Theme QML type and Kirigami has no
    //! equivalent: Kirigami.Units.gridUnit matches the old height but is
    //! roughly 1.8x the old width, so layouts that scale off the width need
    //! the real metric.
    Q_INVOKABLE QSizeF mSize(const QFont &font) const;

private:
    float colorBrightness(QRgb rgb);
    float colorBrightness(float r, float g, float b);

    float colorLumina(QRgb rgb);
    float colorLumina(float r, float g, float b);
};

static QObject *tools_qobject_singletontype_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

// NOTE: QML engine is the owner of this resource
    return new Tools;
}

}

#endif
