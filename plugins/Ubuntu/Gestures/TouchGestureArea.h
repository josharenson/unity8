#ifndef TOUCHGESTUREAREA_H
#define TOUCHGESTUREAREA_H

#include <QQuickItem>

// lib UbuntuGestures
#include <Timer.h>

class TouchOwnershipEvent;
class UnownedTouchEvent;

class GestureTouchPoint : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int id READ id NOTIFY idChanged)
    Q_PROPERTY(bool pressed READ pressed NOTIFY pressedChanged)
    Q_PROPERTY(qreal x READ x NOTIFY xChanged)
    Q_PROPERTY(qreal y READ y NOTIFY yChanged)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
public:
    GestureTouchPoint()
        : m_id(-1)
        , m_pressed(false)
        , m_x(0)
        , m_y(0)
        , m_dragging(false)
    {
    }

    GestureTouchPoint(const GestureTouchPoint& other)
    : QObject(nullptr)
    {
        operator=(other);
    }

    int id() const { return m_id; }
    void setId(int id);

    bool pressed() const { return m_pressed; }
    void setPressed(bool pressed);

    qreal x() const { return m_x; }
    void setX(qreal x);

    qreal y() const { return m_y; }
    void setY(qreal y);

    bool dragging() const { return m_dragging; }
    void setDragging(bool dragging);

    GestureTouchPoint& operator=(const GestureTouchPoint& rhs) {
        if (&rhs == this) return *this;
        m_id = rhs.m_id;
        m_pressed = rhs.m_pressed;
        m_x = rhs.m_x;
        m_y = rhs.m_y;
        m_dragging = rhs.m_dragging;
        return *this;
    }

    bool operator=(const GestureTouchPoint& rhs) const {
        if (&rhs == this) return true;
        return m_id == rhs.m_id &&
                m_pressed == rhs.m_pressed &&
                m_x == rhs.m_x &&
                m_y == rhs.m_y &&
                m_dragging == rhs.m_dragging;
    }
    bool operator!=(const GestureTouchPoint& rhs) const { return !operator=(rhs); }


Q_SIGNALS:
    void idChanged();
    void pressedChanged();
    void xChanged();
    void yChanged();
    void draggingChanged();

private:
    int m_id;
    bool m_pressed;
    qreal m_x;
    qreal m_y;
    bool m_dragging;
};

class TouchGestureArea : public QQuickItem
{
    Q_OBJECT
    Q_ENUMS(Status)

    Q_PROPERTY(int status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
    Q_PROPERTY(QQmlListProperty<GestureTouchPoint> touchPoints READ touchPoints NOTIFY touchPointsUpdated)

    Q_PROPERTY(int minimumTouchPoints READ minimumTouchPoints WRITE setMinimumTouchPoints NOTIFY minimumTouchPointsChanged)
    Q_PROPERTY(int maximumTouchPoints READ maximumTouchPoints WRITE setMaximumTouchPoints NOTIFY maximumTouchPointsChanged)

    Q_PROPERTY(int recognitionPeriod READ recognitionPeriod WRITE setRecognitionPeriod NOTIFY recognitionPeriodChanged)

public:
    // Describes the state of the directional drag gesture.
    enum Status {
        WaitingForTouch,
        Undecided,
        Recognized,
        Rejected
    };
    TouchGestureArea(QQuickItem* parent = NULL);
    ~TouchGestureArea();

    bool event(QEvent *e) override;

    void setRecognitionTimer(UbuntuGestures::AbstractTimer *timer);

    int status() const;
    bool dragging() const;
    QQmlListProperty<GestureTouchPoint> touchPoints();

    int minimumTouchPoints() const;
    void setMinimumTouchPoints(int value);

    int maximumTouchPoints() const;
    void setMaximumTouchPoints(int value);

    int recognitionPeriod() const;
    void setRecognitionPeriod(int value);

Q_SIGNALS:
    void statusChanged(int status);

    void touchPointsUpdated();
    void draggingChanged(bool dragging);
    void minimumTouchPointsChanged(bool value);
    void maximumTouchPointsChanged(bool value);
    void recognitionPeriodChanged(bool value);

    void pressed(const QList<QObject*>& points);
    void released(const QList<QObject*>& points);
    void updated(const QList<QObject*>& points);
    void clicked();

private Q_SLOTS:
    void rejectGesture();

private:
    void touchEvent(QTouchEvent *event) override;
    void touchEvent_waitingForTouch(QTouchEvent *event);
    void touchEvent_undecided(QTouchEvent *event);
    void touchEvent_waitingForOwnership(QTouchEvent *event);
    void touchEvent_recognized(QTouchEvent *event);
    void touchEvent_rejected(QTouchEvent *event);

    void unownedTouchEvent(QTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_undecided(QTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_waitingForOwnership(QTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_recognised(QTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_rejected(QTouchEvent *unownedTouchEvent);

    void touchOwnershipEvent(TouchOwnershipEvent *event);
    void updateTouchPoints(QTouchEvent *event);

    GestureTouchPoint* addTouchPoint(const QTouchEvent::TouchPoint *tp);
    void updateTouchPoint(GestureTouchPoint *iwtp, const QTouchEvent::TouchPoint *tp);
    void clearTouchLists();
    void setDragging(bool dragging);
    void setInternalStatus(uint status);
    void resyncCachedTouchPoints();

    static int touchPoint_count(QQmlListProperty<GestureTouchPoint> *list);
    static GestureTouchPoint* touchPoint_at(QQmlListProperty<GestureTouchPoint> *list, int index);

    uint m_status;
    QSet<int> m_candidateTouches;
    QSet<int> m_watchedTouches;
    UbuntuGestures::AbstractTimer *m_recognitionTimer;

    bool m_dragging;
    QHash<int, GestureTouchPoint*> m_liveTouchPoints;
    QHash<int, GestureTouchPoint*> m_cachedTouchPoints;
    QList<QObject*> m_releasedTouchPoints;
    QList<QObject*> m_pressedTouchPoints;
    QList<QObject*> m_movedTouchPoints;
    int m_minimumTouchPoints;
    int m_maximumTouchPoints;
    int m_recognitionPeriod;
};

QML_DECLARE_TYPE(GestureTouchPoint)

#endif // TOUCHGESTUREAREA_H