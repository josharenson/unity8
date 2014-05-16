AbstractButton { 
                id: root; 
                property var template; 
                property var components; 
                property var cardData; 
                property var artShapeBorderSource; 
                property real fontScale: 1.0; 
                property int headerAlignment: Text.AlignLeft; 
                property int fixedHeaderHeight: -1; 
                property size fixedArtShapeSize: Qt.size(-1, -1); 
                readonly property string title: cardData && cardData["title"] || ""; 
                property bool asynchronous: true; 
                property bool showHeader: true; 
                implicitWidth: childrenRect.width; 
readonly property size artShapeSize: artShapeLoader.item ? Qt.size(artShapeLoader.item.width, artShapeLoader.item.height) : Qt.size(-1, -1);
Item  { 
                    id: artShapeHolder; 
                    height: root.fixedArtShapeSize.height != -1 ? root.fixedArtShapeSize.height : artShapeLoader.height; 
                    width: root.fixedArtShapeSize.width != -1 ? root.fixedArtShapeSize.width : artShapeLoader.width; 
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
                            readonly property real aspect: components !== undefined ? components["art"]["aspect-ratio"] : 1; 
                            readonly property bool aspectSmallerThanImageAspect: aspect < image.aspect; 
                            Component.onCompleted: updateWidthHeightBindings(); 
                            onAspectSmallerThanImageAspectChanged: updateWidthHeightBindings(); 
                            visible: image.status == Image.Ready; 
                            borderSource: artShapeBorderSource; 
                            function updateWidthHeightBindings() { 
                                if (aspectSmallerThanImageAspect) { 
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
Loader { 
            id: overlayLoader; 
            anchors { 
                left: artShapeHolder.left; 
                right: artShapeHolder.right; 
                bottom: artShapeHolder.bottom; 
            } 
            active: artShapeLoader.active && artShapeLoader.item && artShapeLoader.item.image.status === Image.Ready || false; 
            asynchronous: root.asynchronous; 
            visible: showHeader && status == Loader.Ready; 
            sourceComponent: ShaderEffect { 
                id: overlay; 
                height: fixedHeaderHeight != -1 ? fixedHeaderHeight : headerHeight;
                opacity: 0.6; 
                property var source: ShaderEffectSource { 
                    id: shaderSource; 
                    sourceItem: artShapeLoader.item; 
                    onVisibleChanged: if (visible) scheduleUpdate(); 
                    live: false; 
                    sourceRect: Qt.rect(0, artShapeLoader.height - overlay.height, artShapeLoader.width, overlay.height); 
                } 
                vertexShader: " 
                    uniform highp mat4 qt_Matrix; 
                    attribute highp vec4 qt_Vertex; 
                    attribute highp vec2 qt_MultiTexCoord0; 
                    varying highp vec2 coord; 
                    void main() { 
                        coord = qt_MultiTexCoord0; 
                        gl_Position = qt_Matrix * qt_Vertex; 
                    }"; 
                fragmentShader: " 
                    varying highp vec2 coord; 
                    uniform sampler2D source; 
                    uniform lowp float qt_Opacity; 
                    void main() { 
                        lowp vec4 tex = texture2D(source, coord); 
                        gl_FragColor = vec4(0, 0, 0, tex.a) * qt_Opacity; 
                    }"; 
            } 
        }
readonly property int headerHeight: titleLabel.height + titleLabel.anchors.topMargin * 2 + subtitleLabel.height + subtitleLabel.anchors.topMargin;
Label { 
                    id: titleLabel; 
                    objectName: "titleLabel"; 
                    anchors { left: parent.left; 
                            leftMargin: units.gu(1); 
                            right: parent.right; 
                            top: overlayLoader.top; 
                            topMargin: units.gu(1);
}
                    elide: Text.ElideRight; 
                    fontSize: "small"; 
                    wrapMode: Text.Wrap; 
                    maximumLineCount: 2; 
                    font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                    color: "white"; 
                    visible: showHeader && overlayLoader.active; 
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
                               topMargin: units.dp(2);
 }
                        elide: Text.ElideRight; 
                        fontSize: "small"; 
                        font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                        color: "white"; 
                        visible: titleLabel.visible && titleLabel.text; 
                        text: cardData && cardData["subtitle"] || ""; 
                        font.weight: Font.Light; 
                        horizontalAlignment: root.headerAlignment; 
                    }
implicitHeight: subtitleLabel.y + subtitleLabel.height + units.gu(1);
}
