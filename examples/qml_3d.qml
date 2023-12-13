import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import org.julialang

ApplicationWindow {
  id: mainwindow
  title: "3D Surface Demo"
  width: 500
  height: 500 + 30 + 6
  visible: true

  ColumnLayout {
    id: root
    spacing: 6
    anchors.fill: parent

    RowLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignCenter

      Text {
        text: "Field of view:"
      }
      Slider {
        id: fovSlider
        implicitWidth: 100
        implicitHeight: 30
        value: 40
        from: 0
        to: 100
        stepSize: 1
        onValueChanged: {
          parameters.fov = fovSlider.value;
          painter.update()
        }
      }

      Text {
        text: "Camera distance:"
      }
      Slider {
        id: camSlider
        implicitWidth: 100
        implicitHeight: 30
        value: 2
        from: 2
        to: 10
        stepSize: 0.2
        onValueChanged: {
          parameters.cam = camSlider.value;
          painter.update()
        }
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
          Julia.mousePosition(mouse.x, mouse.y, mouse.buttons);
          painter.update()
        }
      }

    }
  }
}
