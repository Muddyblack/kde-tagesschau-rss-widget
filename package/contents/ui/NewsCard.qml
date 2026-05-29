import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: newsCard

    property Item plasmoidRoot
    property ListModel newsListModel

    width: ListView.view ? ListView.view.width : 0
    height: expanded ? compactLayout.implicitHeight + expandedLayout.implicitHeight + 24 : compactLayout.implicitHeight + 16

    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 8
        color: isBreaking ? Qt.rgba(0.9, 0.1, 0.1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
        border.color: isBreaking ? newsCard.plasmoidRoot.breakingRed : Qt.rgba(1, 1, 1, 0.08)
        border.width: isBreaking ? 1.5 : 1
        clip: true

        SequentialAnimation on border.color {
            running: isBreaking
            loops: Animation.Infinite
            ColorAnimation {
                to: Qt.rgba(0.9, 0.1, 0.1, 0.8)
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            ColorAnimation {
                to: Qt.rgba(0.9, 0.1, 0.1, 0.2)
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                var currState = expanded;
                for (var i = 0; i < newsCard.newsListModel.count; i++) {
                    if (i !== index) {
                        newsCard.newsListModel.setProperty(i, "expanded", false);
                    }
                }
                newsCard.newsListModel.setProperty(index, "expanded", !currState);
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
            border.color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
            border.width: 1
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 8

            RowLayout {
                id: compactLayout
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 50
                    height: 50
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.05)
                    visible: !expanded && imageUrl !== ""
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: imageUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 6

                        Rectangle {
                            visible: isBreaking
                            color: newsCard.plasmoidRoot.breakingRed
                            radius: 3
                            width: eilLabel.implicitWidth + 8
                            height: eilLabel.implicitHeight + 4

                            PlasmaComponents.Label {
                                id: eilLabel
                                text: i18n("BREAKING")
                                font.pixelSize: 8
                                font.bold: true
                                color: "#ffffff"
                                anchors.centerIn: parent
                            }
                        }

                        PlasmaComponents.Label {
                            visible: ressort !== ""
                            text: ressort.toUpperCase()
                            font.pixelSize: 9
                            font.bold: true
                            opacity: 0.6
                            color: isBreaking ? "#ff6666" : Kirigami.Theme.highlightColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label {
                            text: newsCard.plasmoidRoot.formatTimeAgo(date)
                            font.pixelSize: 9
                            opacity: 0.5
                            color: Kirigami.Theme.textColor
                        }
                    }

                    PlasmaComponents.Label {
                        text: title
                        font.bold: true
                        font.pixelSize: 11
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: expanded ? 4 : 2
                        elide: expanded ? Text.ElideNone : Text.ElideRight
                    }
                }

                Kirigami.Icon {
                    source: expanded ? "arrow-up" : "arrow-down"
                    width: 12
                    height: 12
                    opacity: 0.4
                }
            }

            ColumnLayout {
                id: expandedLayout
                Layout.fillWidth: true
                visible: expanded
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 130
                    radius: 5
                    color: Qt.rgba(0, 0, 0, 0.2)
                    clip: true
                    visible: imageUrl !== ""

                    Image {
                        anchors.fill: parent
                        source: imageUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                PlasmaComponents.Label {
                    visible: topline !== ""
                    text: topline
                    font.italic: true
                    font.pixelSize: 10
                    opacity: 0.7
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                PlasmaComponents.Label {
                    text: newsCard.plasmoidRoot.cleanHtml(firstSentence)
                    font.pixelSize: 11
                    lineHeight: 1.2
                    opacity: 0.95
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true
                    }

                    QQC2.Button {
                        text: i18n("Read more")
                        onClicked: Qt.openUrlExternally(url)

                        contentItem: RowLayout {
                            spacing: 4
                            Kirigami.Icon {
                                source: "globe"
                                width: 12
                                height: 12
                                isMask: true
                                color: Kirigami.Theme.highlightedTextColor
                            }
                            PlasmaComponents.Label {
                                text: i18n("Open article")
                                font.pixelSize: 9
                                font.bold: true
                                color: Kirigami.Theme.highlightedTextColor
                            }
                        }

                        background: Rectangle {
                            implicitWidth: 100
                            implicitHeight: 24
                            radius: 4
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }
            }
        }
    }
}
