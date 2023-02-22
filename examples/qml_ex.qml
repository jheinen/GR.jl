import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import org.julialang

ApplicationWindow {
  id: mainwindow
  title: "hexbin Demo Application"
  width: 600
  height: 450
  visible: true

  // QTBUG-77958: QtQuick applications don't work on macOS 10.15 Beta 7/8
  // see https://bugreports.qt.io/browse/QTBUG-77958
  //Timer {
  //  interval: 50
  //  repeat: true
  //  running: true
  //  onTriggered: if (mainwindow.active) mainwindow.raise();
  //}

  Text {
    id: xy
    font.pointSize: 12
    font.family: "Courier New"
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
        implicitWidth: 100
        implicitHeight: 30
        value: 30
        from: 10
        to: 60
        stepSize: 1
        onValueChanged: {
          parameters.nbins = nbinsSlider.value;
          painter.update()
        }
      }
    }

    JuliaPaintedItem {
      id: painter
      paintFunction: paint_cfunction
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
    }
  }
}
