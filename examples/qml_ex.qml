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
    font.pointSize: 12
    font.family: "Courier"
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
        id: nbinsSlider
        width: 100
        value: 30
        minimumValue: 10
        maximumValue: 60
        stepSize: 1
      }
    }

    JuliaPaintedItem {
      id: painter
      paintFunction : paint_cfunction
      Layout.fillWidth: true
      Layout.fillHeight: true

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
          xy.text = Julia.mousePosition(mouse.x, mouse.y, 0);
        }
        onWheel: {
          Julia.mousePosition(wheel.x, wheel.y, wheel.angleDelta.y);
          painter.update()
        }
      }

      Connections {
        target: nbinsSlider
        onValueChanged: {
          nbins = nbinsSlider.value;
          painter.update()
        }
      }
    }
  }
}
