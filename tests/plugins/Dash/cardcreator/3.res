AbstractButton { 
                id: root; 
                property var cardData; 
                property string backgroundShapeStyle: "flat"; 
                property real fontScale: 1.0; 
                property var scopeStyle: null; 
                readonly property string title: cardData && cardData["title"] || "";
                property bool showHeader: true;
                implicitWidth: childrenRect.width;
                enabled: true;
                property int fixedHeaderHeight: -1; 
                property size fixedArtShapeSize: Qt.size(-1, -1); 
signal action(var actionId);
Loader  {
                                id: artShapeLoader; 
                                height: root.fixedArtShapeSize.height; 
                                width: root.fixedArtShapeSize.width; 
                                anchors { horizontalCenter: parent.horizontalCenter; }
                                objectName: "artShapeLoader"; 
                                readonly property string cardArt: cardData && cardData["art"] || decodeURI("IHAVE%5C%22ESCAPED%5C%22QUOTES%5C%22");
                                onCardArtChanged: { if (item) { item.image.source = cardArt; } }
                                active: cardArt != "";
                                asynchronous: true;
                                visible: status === Loader.Ready;
                                sourceComponent: Item {
                                    id: artShape;
                                    objectName: "artShape";
                                    visible: image.status === Image.Ready;
                                    readonly property alias image: artImage;
                                    ProportionalShape {
                                        anchors.left: parent.left;
                                        anchors.right: parent.right;
                                        source: artImage;
                                        aspect: UbuntuShape.DropShadow;
                                    }
                                    width: root.fixedArtShapeSize.width;
                                    height: root.fixedArtShapeSize.height;
                                    CroppedImageMinimumSourceSize {
                                        id: artImage;
                                        objectName: "artImage";
                                        source: artShapeLoader.cardArt;
                                        asynchronous: true;
                                        visible: false;
                                        width: root.width;
                                        height: width / (root.fixedArtShapeSize.width / root.fixedArtShapeSize.height);
                                        onStatusChanged: if (status === Image.Error) source = decodeURI("IHAVE%5C%22ESCAPED%5C%22QUOTES%5C%22");
                                    }
                                } 
                        }
readonly property int headerHeight: titleLabel.height + subtitleLabel.height + subtitleLabel.anchors.topMargin;
Label { 
                        id: titleLabel; 
                        objectName: "titleLabel"; 
                        anchors { right: parent.right;
                        left: parent.left;
                        top: artShapeLoader.bottom;
                        topMargin: units.gu(1);
                        } 
                        elide: Text.ElideRight; 
                        fontSize: "small"; 
                        wrapMode: Text.Wrap; 
                        maximumLineCount: 2; 
                        font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                        color: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText;
                        visible: showHeader ; 
                        width: undefined;
                        text: root.title; 
                        font.weight: Font.Normal; 
                        horizontalAlignment: Text.AlignLeft;
                    }
Label { 
                            id: subtitleLabel; 
                            objectName: "subtitleLabel"; 
                            anchors { left: titleLabel.left; 
                            leftMargin: titleLabel.leftMargin; 
                            right: titleLabel.right; 
                            top: titleLabel.bottom; 
                            } 
                            anchors.topMargin: units.dp(2);
                            elide: Text.ElideRight; 
                            maximumLineCount: 1; 
                            fontSize: "x-small"; 
                            font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                            color: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText;
                            visible: titleLabel.visible && titleLabel.text; 
                            text: cardData && cardData["subtitle"] || ""; 
                            font.weight: Font.Light; 
                        }
implicitHeight: subtitleLabel.y + subtitleLabel.height + units.gu(1);
}
