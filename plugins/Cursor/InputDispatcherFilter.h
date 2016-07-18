/*
 * Copyright (C) 2016 Canonical, Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranties of MERCHANTABILITY,
 * SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef INPUTDISPATCHERFILTER_H
#define INPUTDISPATCHERFILTER_H

#include <QObject>
#include <QPointF>
#include <QSet>

class MousePointer;
class QScreen;

class InputDispatcherFilter : public QObject
{
    Q_OBJECT
public:
    static InputDispatcherFilter *instance();

    void registerPointer(MousePointer* pointer);

    void unregisterPointer(MousePointer* pointer);

    void setPosition(const QPointF &pos);

Q_SIGNALS:
    void pushedLeftBoundary(QScreen* screen, qreal amount, Qt::MouseButtons buttons);
    void pushedRightBoundary(QScreen* screen, qreal amount, Qt::MouseButtons buttons);

protected:
    InputDispatcherFilter(QObject* parent = nullptr);

    bool eventFilter(QObject *o, QEvent *e);

    QPointF adjustedPositionForMovement(const QPointF& pt, const QPointF& movement) const;
    QScreen* screenAt(const QPointF& pt) const;

private:
    QObject* m_inputDispatcher;
    QSet<MousePointer*> m_pointers;
    QPointF mousePosition;
};

#endif // INPUTDISPATCHERFILTER_H
