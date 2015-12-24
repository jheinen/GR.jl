module jlgr

using Compat
import GR

if VERSION >= v"0.4-"
  const None = Union{}
end

@compat typealias PlotArg Union{AbstractString, AbstractVector, AbstractMatrix}

const gr3 = GR.gr3

kvs = Dict()

isrowvec(x::AbstractArray) = ndims(x) == 2 && size(x, 1) == 1 && size(x, 2) > 1

isvector(x::AbstractVector) = true
isvector(x::AbstractMatrix) = size(x, 1) == 1

function plot_data(x, y, spec;
                   bgcolor=0,
                   window=(-1, 1, -1, 1),
                   viewport=(0.1, 0.95, 0.1, 0.7),
                   scale=0,
                   clear=true,
                   update=true)
    GR.setwsviewport(0, 0.14, 0, 0.105)
    GR.setwswindow(0, 1, 0, 0.75)
    if clear
        GR.clearws()
        xmin, xmax, ymin, ymax = window

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
        charheight = 0.03 * (viewport[4] - viewport[3])
        GR.setcharheight(charheight)
        GR.grid(xtick, ytick, xmax, ymax, majorx, majory)
        ticksize = 0.0125 * (viewport[2] - viewport[1])
        GR.axes(xtick, ytick, xmin, ymin, majorx, majory, ticksize)
        GR.axes(xtick, ytick, xmax, ymax, -majorx, -majory, -ticksize)
    end
    mask = GR.uselinespec(spec)
    mask in (0, 1, 3, 4, 5) && GR.polyline(x, y)
    mask & 0x02 != 0 && GR.polymarker(x, y)
    if update
        GR.updatews()
    end
end

function plot(args::PlotArg...; kv...)
    args = Any[args...]

    kv = merge(kvs, Dict(kv))

    parsed_args = Any[]

    while length(args) > 0
        local x, y
        a = shift!(args);
        if isa(a, AbstractVecOrMat)
            elt = eltype(a)
            if elt <: Complex
                x = real(a)
                y = imag(a)
            elseif length(args) > 0 && isa(args[1], AbstractVecOrMat) &&
               elt <: Real && eltype(args[1]) <: Real
                x = a
                y = shift!(args);
            elseif elt <: Real
                y = a
                n = isrowvec(y) ? size(y, 2) : size(y, 1)
                x = linspace(1, n, n)
            else
                error("expected Real or Complex")
            end
        else
            error("expected array or function")
        end
        spec = ""
        if length(args) > 0 && isa(args[1], AbstractString)
            spec = shift!(args);
        end
        push!(parsed_args, (x, y, spec))
    end

    items = Any[]

    for (a, b, spec) in parsed_args
        x, y = a, b

        isvector(x) && (x = vec(x))
        isvector(y) && (y = vec(y))

        local xys
        if isa(x, AbstractVector) && isa(y, AbstractVector)
            xys = [ (x, y) ]
        elseif isa(x, AbstractVector)
            xys = length(x) == size(y, 1) ?
                  [ (x, sub(y, :, j)) for j = 1:size(y, 2) ] :
                  [ (x, sub(y, i, :)) for i = 1:size(y, 1) ]
        elseif isa(y, AbstractVector)
            xys = size(x, 1) == length(y) ?
                  [ (sub(x, :, j), y) for j = 1:size(x, 2) ] :
                  [ (sub(x, i, :), y) for i = 1:size(x, 1) ]
        else
            @assert size(x) == size(y)
            xys = [ (sub(x, :, j), sub(y, :, j)) for j = 1:size(y, 2) ]
        end

        for (x, y) in xys
            push!(items, (x, y, spec))
        end
    end

    xmin = ymin = typemax(Float64)
    xmax = ymax = typemin(Float64)
    for (x, y, spec) in items
        xmin = min(minimum(x), xmin)
        xmax = max(maximum(x), xmax)
        ymin = min(minimum(y), ymin)
        ymax = max(maximum(y), ymax)
    end

    xmin, xmax = GR.adjustlimits(xmin, xmax)
    ymin, ymax = GR.adjustlimits(ymin, ymax)
    GR.setwindow(xmin, xmax, ymin, ymax)

    clear = true
    for (x, y, spec) in items
        GR.savestate()
        plot_data(x, y, spec, window=(xmin, xmax, ymin, ymax), clear=clear)
        GR.restorestate()
        clear = false
    end

    if haskey(kv, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.text(0.5, 0.75, kv[:title])
        GR.restorestate()
    end
    if haskey(kv, :xlabel)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_BOTTOM)
        GR.text(0.5, 0, kv[:xlabel])
        GR.restorestate()
    end
    if haskey(kv, :ylabel)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.setcharup(-1, 0)
        GR.text(0, 0.4, kv[:ylabel])
        GR.restorestate()
    end
    GR.updatews()

    if GR.isinline()
        return GR.show()
    end
end

function title(s)
    kvs[:title] = s
end

function xlabel(s)
    kvs[:xlabel] = s
end

function ylabel(s)
    kvs[:ylabel] = s
end

function plot2d(x, y;
                bgcolor=0,
                viewport=(0.1, 0.95, 0.1, 0.95),
                window=(-1, 1, -1, 1),
                scale=0,                       # ignored
                grid=true,                     # ignored
                linetype=GR.LINETYPE_SOLID,    # ignored
                markertype=GR.MARKERTYPE_DOT,  # ignored
                clear=true,
                update=true)
    println("plot2d: This function is deprecated; use plot() instead")
    plot_data(x, y, "", bgcolor=bgcolor, window=window, viewport=viewport,
              scale=scale, clear=clear, update=update)
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
