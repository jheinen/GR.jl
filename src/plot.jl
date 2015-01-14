function plot(x, y,
              bgcolor=0,
              viewport=(0.1, 0.95, 0.1, 0.95),
              window=None,
              scale=0,
              drawgrid=true,
              linetype=LINETYPE_SOLID,
              markertype=MARKERTYPE_DOT,
              clear=true,
              update=true)
    if clear
        clearws()
    end
    if window == None
        if scale & OPTION_X_LOG == 0
            xmin, xmax = adjustrange(minimum(x), maximum(x))
        else
            xmin, xmax = (minimum(x), maximum(x))
        end
        if scale & OPTION_Y_LOG == 0
            ymin, ymax = adjustrange(minimum(y), maximum(y))
        else
            ymin, ymax = (minimum(y), maximum(y))
        end
    else
        xmin, xmax, ymin, ymax = window
    end
    if scale & OPTION_X_LOG == 0
        majorx = 5
        xtick = tick(xmin, xmax) / majorx
    else
        xtick = majorx = 1
    end
    if scale & OPTION_Y_LOG == 0
        majory = 5
        ytick = tick(ymin, ymax) / majory
    else
        ytick = majory = 1
    end
    setviewport(viewport[1], viewport[2], viewport[3], viewport[4])
    setwindow(xmin, xmax, ymin, ymax)
    setscale(scale)
    if bgcolor != 0
        setfillintstyle(1)
        setfillcolorind(bgcolor)
        fillrect(xmin, xmax, ymin, ymax)
    end
    charheight = 0.024 * (viewport[4] - viewport[3])
    setcharheight(charheight)
    if drawgrid
         grid(xtick, ytick, xmax, ymax, majorx, majory)
    end
    axes(xtick, ytick, xmin, ymin, majorx, majory, 0.01)
    axes(xtick, ytick, xmax, ymax, -majorx, -majory, -0.01)
    setlinetype(linetype)
    polyline(x, y)
    if markertype != MARKERTYPE_DOT
        setmarkertype(markertype)
        polymarker(x, y)
    end
    if update
        updatews()
    end
end
