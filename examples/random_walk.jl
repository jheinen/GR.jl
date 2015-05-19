using GR

srand(37)
y = randn(20, 500)

setviewport(0.1, 0.95, 0.1, 0.95)
setcharheight(0.020)
settextcolorind(82)
setfillcolorind(90)
setfillintstyle(1)

for x in 1:5000
  clearws()
  setwindow(x, x+500, -200, 200)
  fillrect(x, x+500, -200, 200)
  setlinecolorind(0);  grid(50, 50, 0, -200, 2, 2)
  setlinecolorind(82); axes(50, 50, x, -200, 2, 2, -0.005)
  y = hcat(y, randn(20))
  for i in 1:20
    setlinecolorind(980 + i)
    s = cumsum(reshape(y[i,:], x+500))
    polyline([x:x+500;], s[x:x+500])
  end
  updatews()
end
