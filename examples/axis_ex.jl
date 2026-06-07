using GR
using Dates

function myaxis(xmin, xmax, position)
  setwindow(xmin, xmax, 0, 1)
  setcharheight(0.012)
  x_axis = axis("TIMESTAMP", tick_size=0.004)
  x_axis.position = position
  x_axis.label_position = position - 2 * x_axis.tick_size
  drawaxis(x_axis)
  updatews()
end

function main()
  setwsviewport(0, 0.24, 0, 0.12)
  setwswindow(0, 1, 0, 0.5)
  settextfontprec(232, 3)
  setcharheight(0.016)
  setscientificformat(3)
  setviewport(0.1, 0.95, 0.1, 0.45)
  setwindow(0.1, 100, -10, 20)
  setscale(1)
  x_axis = axis("X")
  x_axis.tick_labels[2].label = "1"
  drawaxis(x_axis)
  y_axis = axis("Y", major_count=5)
  drawaxis(y_axis)
  updatews()
  read(stdin, Char)
  drawaxes(x_axis, y_axis)
  updatews()
  read(stdin, Char)
  clearws()
  t = datetime2unix(now())
  myaxis(t - 60*24, t, 1.0)
  myaxis(t - 60*60*24, t, 0.8)
  myaxis(t - 7*60*60*24, t, 0.6)
  myaxis(t - 30*60*60*24, t, 0.4)
  myaxis(t - 365*60*60*24, t, 0.2)
  myaxis(t - 10*365*60*60*24, t, 0)
end

main()
