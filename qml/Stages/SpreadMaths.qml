import QtQuick 2.2
import Ubuntu.Components 1.1
import Utils 0.1
import Unity.Application 0.1

Item {

    Label {
        anchors {left: parent.left; top: parent.top }
        text: "prog:" + transitionCurve.progress.toFixed(2)
        color: leftFoldingAreaProgress > 0 || rightFoldingAreaProgress > 0 ? "red" : "black"
    }

    id: root
    anchors { left: parent.left; top: parent.top; margins: units.gu(1) }

    property int itemIndex: 0
    property int totalItems: 0
    property Item flickable: null
    property int margins: units.gu(5)
    property int foldingAreaWidth: units.gu(10)

    property int maxVisibleItems: 10

    property int sceneHeight: 100
    property int spreadHeight: sceneHeight * 0.4
    property int itemHeight: sceneHeight / 2

    readonly property int flickableWidth: flickable ? flickable.width : 0
    readonly property int flickableContentWidth: flickable ? flickable.contentWidth: 0
    readonly property real flickableProgress: flickable ? flickable.contentX / (flickable.contentWidth -  flickableWidth) : 0

    readonly property int contentWidth: flickableWidth - root.margins * 2

    readonly property int unfoldedDistance: (contentWidth - foldingAreaWidth) / maxVisibleItems

    // Internal
    readonly property real progressSlice: 1 / totalItems;
    readonly property real startProgress: (index - maxVisibleItems/2) * progressSlice
    readonly property real endProgress: (index + maxVisibleItems/2) * progressSlice

//    readonly property real startX: index < maxVisibleItems ?
//                                       margins + index * unfoldedDistance
//                                     : contentWidth - foldingAreaWidth + (startLayout.value * foldingAreaWidth)

    readonly property real startX: contentWidth - foldingAreaWidth + (startLayout.value * foldingAreaWidth)

//    readonly property real endX: totalItems - maxVisibleItems < index ?
//                                     contentWidth - (totalItems - index) * unfoldedDistance
//                                   : margins + foldingAreaWidth - (endLayout.value * foldingAreaWidth)

    readonly property real endX: margins + foldingAreaWidth - (endLayout.value * foldingAreaWidth)

    readonly property int animatedX: transitionCurve.value * (endX - startX) + startX

    readonly property int animatedY: sceneHeight - itemHeight - (sceneHeight * 0.2);

    property int leftEndFoldedAngle: 70
    property int rightEndFoldedAngle: 65
    property int unfoldedAngle: 30

    // faw : 1 = x : p
    property real leftFoldingAreaProgress: (foldingAreaWidth + margins - animatedX) / foldingAreaWidth
    property real rightFoldingAreaProgress: (animatedX + margins*2 - contentWidth) / foldingAreaWidth


    // x : foldingAreaWidth = leftEndFoldedAngle: unfoldedAngle

    readonly property int animatedAngle: 1/*leftFoldingAreaProgress > 0 ?
                                             linearAnimation(0, 1, unfoldedAngle, leftEndFoldedAngle, leftFoldingAreaProgress)
                                           : rightFoldingAreaProgress > 0 ?
                                                 linearAnimation(0, 1, unfoldedAngle, rightEndFoldedAngle, rightFoldingAreaProgress)
                                               : unfoldedAngle*/

    onAnimatedAngleChanged: if (index == 10) print("**** animated angle", animatedAngle, rightFoldingAreaProgress)

    function desktopScale(sceneHeight, itemHeight) {
        var maxHeight = sceneHeight * 0.35;
        if (itemHeight > maxHeight) {
            return maxHeight / itemHeight
        }
        return 1;
    }

    readonly property real scale: 1

    readonly property real tileInfoOpacity: 1

    function linearAnimation(startProgress, endProgress, startValue, endValue, progress) {
        // progress : progressDiff = value : valueDiff => value = progress * valueDiff / progressDiff
        return (progress - startProgress) * (endValue - startValue) / (endProgress - startProgress) + startValue;
    }

    EasingCurve {
        id: transitionCurve
        type: EasingCurve.InOutSine

        readonly property real normalizedEndProgress: endProgress - startProgress
        readonly property real normalizedProgress: (root.flickableProgress - root.startProgress) / normalizedEndProgress
        progress: normalizedProgress
    }

    EasingCurve {
        id: startLayout
        type: EasingCurve.OutSine
        // total : 1 = index : p
        progress: 1.0 * index / root.totalItems
    }

    EasingCurve {
        id: endLayout
        type: EasingCurve.OutSine
        // total : 1 = index : p
        progress: 1 - (1.0 * index / root.totalItems)
    }
}
