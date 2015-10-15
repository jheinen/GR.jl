module jlgr

import GR

if VERSION >= v"0.4-"
  const None = Union{}
end

const gr3 = GR.gr3

function plot(x, y;
              bgcolor=0,
              viewport=(0.1, 0.95, 0.1, 0.95),
              window=None,
              scale=0,
              grid=true,
              linetype=GR.LINETYPE_SOLID,
              markertype=GR.MARKERTYPE_DOT,
              clear=true,
              update=true)
    if clear
        GR.clearws()
    end
    if window == None
        if scale & GR.OPTION_X_LOG == 0
            xmin, xmax = GR.adjustrange(minimum(x), maximum(x))
        else
            xmin, xmax = (minimum(x), maximum(x))
        end
        if scale & GR.OPTION_Y_LOG == 0
            ymin, ymax = GR.adjustrange(minimum(y), maximum(y))
        else
            ymin, ymax = (minimum(y), maximum(y))
        end
    else
        xmin, xmax, ymin, ymax = window
    end
    if scale & GR.OPTION_X_LOG == 0
        majorx = 5
        xtick = GR.tick(xmin, xmax) / majorx
    else
        xtick = majorx = 1
    end
    if scale & GR.OPTION_Y_LOG == 0
        majory = 5
        ytick = GR.tick(ymin, ymax) / majory
    else
        ytick = majory = 1
    end
    GR.setviewport(viewport[1], viewport[2], viewport[3], viewport[4])
    GR.setwindow(xmin, xmax, ymin, ymax)
    GR.setscale(scale)
    if bgcolor != 0
        GR.setfillintstyle(1)
        GR.setfillcolorind(bgcolor)
        GR.fillrect(xmin, xmax, ymin, ymax)
    end
    charheight = 0.024 * (viewport[4] - viewport[3])
    GR.setcharheight(charheight)
    if grid
         GR.grid(xtick, ytick, xmax, ymax, majorx, majory)
    end
    ticksize = 0.0125 * (viewport[2] - viewport[1])
    GR.axes(xtick, ytick, xmin, ymin, majorx, majory, ticksize)
    GR.axes(xtick, ytick, xmax, ymax, -majorx, -majory, -ticksize)
    GR.setlinetype(linetype)
    GR.polyline(x, y)
    if markertype != GR.MARKERTYPE_DOT
        GR.setmarkertype(markertype)
        GR.polymarker(x, y)
    end
    if update
        GR.updatews()
    end

    if GR.isinline()
        return GR.show()
    end
end

function _guessdimension(len)
    x = round(sqrt(len))
    d = Array((Int, Int), 0)
    while x >= 1
        y = div(len, x)
        if x * y == len
            push!(d, (x, y))
        end
        x -= 1
    end
    return sort(d, rev=true)
end

function plot3d(z;
                viewport=(0.1, 0.9, 0.1, 0.9),
                rotation=30,
                tilt=50,
                colormap=1,
                option=4,
                contours=true,
                xtitle="",
                ytitle="",
                ztitle="",
                accelerate=false,
                clear=true,
                update=true)
    if clear
        GR.clearws()
    end
    xmin, ymin = (1, 1)
    if ndims(z) == 2
        xmax, ymax = size(z)
        z = reshape(z, xmax * ymax)
    else
        xmax, ymax = _guessdimension(length(z))[1]
    end
    zmin = minimum(z)
    zmax = maximum(z)
    xtick = GR.tick(xmin, xmax) / 5
    ytick = GR.tick(ymin, ymax) / 5
    x = linspace(1, xmax, round(xmax))
    y = linspace(1, ymax, round(ymax))
    zmin, zmax = GR.adjustrange(zmin, zmax)
    ztick = GR.tick(zmin, zmax) / 5
    GR.setviewport(viewport[1], viewport[2], viewport[3], viewport[4])
    GR.setwindow(xmin, xmax, ymin, ymax)
    GR.setspace(zmin, zmax, rotation, tilt)
    charheight = 0.024 * (viewport[4] - viewport[3])
    GR.setcharheight(charheight)
    GR.setcolormap(colormap)
    if accelerate
        gr3.surface(x, y, z, option)
    else
        GR.surface(x, y, z, option)
    end

    ticksize = 0.0125 * (viewport[2] - viewport[1])
    if rotation != 0 || tilt != 90
        GR.axes3d(xtick, 0, ztick, xmin, ymin, zmin, 5, 0, 5, -ticksize)
        GR.axes3d(0, ytick, 0, xmax, ymin, zmin, 0, 5, 0, ticksize)
    end
    if contours
        GR.contour(x, y, [], z, 0)
    end
    if rotation == 0 && tilt == 90
        GR.axes(xtick, ytick, xmin, ymin, 5, 5, -ticksize)
    end
    if xtitle != "" || ytitle != "" || ztitle != ""
        GR.titles3d(xtitle, ytitle, ztitle)
    end
    if update
        GR.updatews()
    end

    if GR.isinline()
        return GR.show()
    end
end

function imshow(data; cmap=GR.COLORMAP_GRAYSCALE)
    height, width = size(data)
    d = float(reshape(data, width * height))
    ca = round(8 + 72 * (d - minimum(d)) / (maximum(d) - minimum(d)))
    GR.clearws()
    if width < height
        ratio = float(width) / height
        xmin = max(0.5 * (1 - ratio), 0)
        xmax = min(xmin + ratio, 1)
        ymin = 0
        ymax = 1
    else
        ratio = float(height) / width
        xmin = 0
        xmax = 1
        ymin = max(0.5 * (1 - ratio), 0)
        ymax = min(ymin + ratio, 1)
    end
    GR.selntran(0)
    GR.setcolormap(cmap)
    GR.cellarray(xmin, xmax, ymin, ymax, width, height, ca)
    GR.updatews()

    if GR.isinline()
        return GR.show()
    end
end

end # module
