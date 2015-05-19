#!/usr/bin/env julia

import GR

srand(0)
xd = -2 + 4 * rand(100)
yd = -2 + 4 * rand(100)
zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

GR.setviewport(0.1, 0.95, 0.1, 0.95)
GR.setwindow(-2, 2, -2, 2)
GR.setspace(-0.5, 0.5, 0, 90)
GR.setmarkersize(1)
GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
GR.setcharheight(0.024)
GR.settextalign(2, 0)
GR.settextfontprec(3, 0)

x, y, z = GR.gridit(xd, yd, zd, 200, 200)
h = linspace(-0.5, 0.5, 20)
GR.surface(x, y, z, 5)
GR.contour(x, y, h, z, 0)
GR.polymarker(xd, yd)
GR.axes(0.25, 0.25, -2, -2, 2, 2, 0.01)

GR.updatews()
