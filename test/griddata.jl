srand(0)
xd = -2 + 4 * rand(100)
yd = -2 + 4 * rand(100)
zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

setviewport(0.1, 0.95, 0.1, 0.95)
setwindow(-2, 2, -2, 2)
setspace(-0.5, 0.5, 0, 90)
setmarkersize(1)
setmarkertype(-1)
setcharheight(0.024)
settextalign(2, 0)
settextfontprec(3, 0)

x, y, z = gridit(xd, yd, zd, 200, 200)
h = linspace(-0.5, 0.5, 20)
surface(x, y, z, 5)
contour(x, y, h, z, 0)
polymarker(xd, yd)
axes(0.25, 0.25, -2, -2, 2, 2, 0.01)

updatews()
emergencyclosegks()
