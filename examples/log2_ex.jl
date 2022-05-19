#!/usr/bin/env julia

import GR

function main()
    x = LinRange(0, 20, 50)
    y = x .^ 2

    GR.setviewport(0.1, 0.95, 0.1, 0.95)
    GR.setwindow(0, 20, 0.2, 400)
    GR.setscale(GR.OPTION_Y_LOG2)
    GR.settextfontprec(233, 3)

    GR.setmarkersize(1)
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.polymarker(x, y)

    GR.axes(2, 2, 0, 0.2, 1, 2, 0.005)

    GR.updatews()
end

main()
