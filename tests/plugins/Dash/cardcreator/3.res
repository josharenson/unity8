AbstractButton { 
                id: root; 
                property var template; 
                property var components; 
                property var cardData; 
                property var artShapeBorderSource: undefined; 
                property real fontScale: 1.0; 
                property int headerAlignment: Text.AlignLeft; 
                property int fixedHeaderHeight: -1; 
                property size fixedArtShapeSize: Qt.size(-1, -1); 
                readonly property string title: cardData && cardData["title"] || ""; 
                property bool asynchronous: true; 
                property bool showHeader: true; 
                implicitWidth: childrenRect.width; 
onArtShapeBorderSourceChanged: { if (artShapeBorderSource !== undefined && artShapeLoader.item) artShapeLoader.item.borderSource = artShapeBorderSource; } 
readonly property size artShapeSize: artShapeLoader.item ? Qt.size(artShapeLoader.item.width, artShapeLoader.item.height) : Qt.size(-1, -1);
Item  { 
                    id: artShapeHolder; 
                    height: root.fixedArtShapeSize.height > 0 ? root.fixedArtShapeSize.height : artShapeLoader.height;
                    width: root.fixedArtShapeSize.width > 0 ? root.fixedArtShapeSize.width : artShapeLoader.width;
                    anchors { horizontalCenter: parent.horizontalCenter; }
                    Loader { 
                        id: artShapeLoader; 
                        objectName: "artShapeLoader"; 
                        active: cardData && cardData["art"] || false; 
                        asynchronous: root.asynchronous; 
                        visible: status == Loader.Ready; 
                        sourceComponent: UbuntuShape { 
                            id: artShape; 
                            objectName: "artShape"; 
                            radius: "medium"; 
                            visible: image.status == Image.Ready; 
                            readonly property real fixedArtShapeSizeAspect: (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) ? root.fixedArtShapeSize.width / root.fixedArtShapeSize.height : -1;
                            readonly property real aspect: fixedArtShapeSizeAspect > 0 ? fixedArtShapeSizeAspect : components !== undefined ? components["art"]["aspect-ratio"] : 1;
                            readonly property bool aspectSmallerThanImageAspect: aspect < image.aspect;
                            Component.onCompleted: { updateWidthHeightBindings(); if (artShapeBorderSource !== undefined) borderSource = artShapeBorderSource; }
                            onAspectSmallerThanImageAspectChanged: updateWidthHeightBindings();
                            Connections { target: root; onFixedArtShapeSizeChanged: updateWidthHeightBindings(); }
                            function updateWidthHeightBindings() {
                                if (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) {
                                            width = root.fixedArtShapeSize.width;
                                            height = root.fixedArtShapeSize.height;
                                } else if (aspectSmallerThanImageAspect) {
                                    width = Qt.binding(function() { return !visible ? 0 : image.width });
                                    height = Qt.binding(function() { return !visible ? 0 : image.fillMode === Image.PreserveAspectCrop ? image.height : width / image.aspect });
                                } else {
                                    width = Qt.binding(function() { return !visible ? 0 : image.fillMode === Image.PreserveAspectCrop ? image.width : height * image.aspect });
                                    height = Qt.binding(function() { return !visible ? 0 : image.height });
                                }
                            } 
                            image: Image { 
                                objectName: "artImage"; 
                                source: cardData && cardData["art"] || ""; 
                                cache: true; 
                                asynchronous: root.asynchronous; 
                                fillMode: components && components["art"]["fill-mode"] === "fit" ? Image.PreserveAspectFit: Image.PreserveAspectCrop; 
                                readonly property real aspect: implicitWidth / implicitHeight; 
                                width: root.width; 
                                height: width / artShape.aspect;
                            } 
                        } 
                    } 
                }
readonly property int headerHeight: titleLabel.height + subtitleLabel.height + subtitleLabel.anchors.topMargin;
Label { 
                    id: titleLabel; 
                    objectName: "titleLabel"; 
                    anchors { right: parent.right;left: parent.left;
top: artShapeHolder.bottom; 
                                         topMargin: units.gu(1);
}
                    elide: Text.ElideRight; 
                    fontSize: "small"; 
                    wrapMode: Text.Wrap; 
                    maximumLineCount: 2; 
                    font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                    color: "grey"; 
                    visible: showHeader ; 
                    text: root.title; 
                    font.weight: components && components["subtitle"] ? Font.DemiBold : Font.Normal; 
                    horizontalAlignment: root.headerAlignment; 
                }
Label { 
                        id: subtitleLabel; 
                        objectName: "subtitleLabel"; 
                        anchors { left: titleLabel.left; 
                               leftMargin: titleLabel.leftMargin; 
                               right: titleLabel.right; 
                               top: titleLabel.bottom; 
                               topMargin: units.dp(2); }
                        elide: Text.ElideRight; 
                        fontSize: "small"; 
                        font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                        color: "grey"; 
                        visible: titleLabel.visible && titleLabel.text; 
                        text: cardData && cardData["subtitle"] || ""; 
                        font.weight: Font.Light; 
                        horizontalAlignment: root.headerAlignment; 
                    }
implicitHeight: subtitleLabel.y + subtitleLabel.height + units.gu(1);
}
