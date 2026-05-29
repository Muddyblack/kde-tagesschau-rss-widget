import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

Item {
    id: financeCard

    property Item plasmoidRoot

    width: GridView.view ? GridView.view.cellWidth : 0
    height: GridView.view ? GridView.view.cellHeight : 0

    Rectangle {
        id: cardRect
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.03)
        border.color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("https://finance.yahoo.com/quote/" + model.symbol)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: model.name
                    font.bold: true
                    font.pixelSize: 11
                    color: "#ffffff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    color: model.change >= 0 ? Qt.rgba(0, 0.8, 0, 0.15) : Qt.rgba(0.8, 0, 0, 0.15)
                    border.color: model.change >= 0 ? "#00ff00" : "#ff0000"
                    border.width: 0.5
                    radius: 4
                    width: changeLabel.implicitWidth + 8
                    height: changeLabel.implicitHeight + 4

                    PlasmaComponents.Label {
                        id: changeLabel
                        text: (model.change >= 0 ? "+" : "") + model.change.toFixed(2) + "%"
                        font.pixelSize: 8
                        font.bold: true
                        color: model.change >= 0 ? "#55ff55" : "#ff5555"
                        anchors.centerIn: parent
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: model.symbol
                    font.pixelSize: 8
                    opacity: 0.5
                    color: "#ffffff"
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: financeCard.plasmoidRoot.formatPrice(model.price, model.symbol)
                    font.bold: true
                    font.pixelSize: 11
                    color: "#ffffff"
                }
            }
        }
    }
}
