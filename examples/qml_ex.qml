import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.1

ApplicationWindow {
  title: "hexbin Demo Application"
  width: 600
  height: 450
  visible: true

  Text {
    id: xy
    x: 5
    y: 5
    text: ""
  }

  ColumnLayout {
    id: root
    spacing: 6
    anchors.fill: parent

    RowLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignCenter

      Text {
        text: "Number of bins:"
      }

      Slider {
        id: nbins
        width: 100
        value: 30.
        minimumValue: 10.
        maximumValue: 60.
      }
    }

    JuliaPaintedItem {
      id: painter
      paintFunction : paint_cfunction
      Layout.fillWidth: true
      Layout.fillHeight: true

      MouseArea {
        anchors.fill: parent
        onClicked: { nbins.value = 30 }
        hoverEnabled: true
        onPositionChanged: {
          xy.text = Julia.mousePosition(mouse.x, mouse.y);
        }
      }

      Connections {
        target: nbins
        onValueChanged: {
          parameters.nbins = nbins.value;
          painter.update()
        }
      }
    }
  }
}
