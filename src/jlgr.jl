module jlgr

using Compat
import GR

if VERSION >= v"0.4-"
  const None = Union{}
  macro _tuple(t)
    :( Tuple{$t} )
  end
else
  macro _tuple(t)
    :( () )
  end
end

@compat typealias PlotArg Union{AbstractString, AbstractVector, AbstractMatrix}

const gr3 = GR.gr3

const plot_kind = [:line, :scatter, :hist]

type PlotObject
    args
    kvs
end

function Figure(width=600, height=450)
    args = @_tuple(Any)
    kvs = Dict()
    kvs[:size] = (width, height)
    PlotObject(args, kvs)
end

plt = Figure()

isrowvec(x::AbstractArray) = ndims(x) == 2 && size(x, 1) == 1 && size(x, 2) > 1

isvector(x::AbstractVector) = true
isvector(x::AbstractMatrix) = size(x, 1) == 1

function plot_data(; kv...)
    merge!(plt.kvs, Dict(kv))

    kind = get(plt.kvs, :kind, :line)

    subplot = [0, 1, 0, 1]
    mwidth, mheight, width, height = GR.inqdspsize()
    w, h = plt.kvs[:size]
    viewport = zeros(4)
    if w > h
        ratio = float(h) / w
        msize = mwidth * w / width
        GR.setwsviewport(0, msize, 0, msize * ratio)
        GR.setwswindow(0, 1, 0, ratio)
        viewport[1] = subplot[1] + 0.1  * (subplot[2] - subplot[1])
        viewport[2] = subplot[1] + 0.95 * (subplot[2] - subplot[1])
        viewport[3] = ratio * (subplot[3] + 0.1  * (subplot[4] - subplot[3]))
        viewport[4] = ratio * (subplot[3] + 0.95 * (subplot[4] - subplot[3]))
    else
        ratio = float(w) / h
        msize = mheight * h / height
        GR.setwsviewport(0, msize * ratio, 0, msize)
        GR.setwswindow(0, ratio, 0, 1)
        viewport[1] = ratio * (subplot[1] + 0.1  * (subplot[2] - subplot[1]))
        viewport[2] = ratio * (subplot[1] + 0.95 * (subplot[2] - subplot[1]))
        viewport[3] = subplot[3] + 0.1  * (subplot[4] - subplot[3])
        viewport[4] = subplot[3] + 0.95 * (subplot[4] - subplot[3])
    end
    GR.setviewport(viewport[1], viewport[2], viewport[3], viewport[4])

    scale = 0
    get(plt.kvs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
    get(plt.kvs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
    get(plt.kvs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
    get(plt.kvs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)

    xmin, xmax = plt.kvs[:xrange]
    ymin, ymax = plt.kvs[:yrange]
    if scale & GR.OPTION_X_LOG == 0
        xmin, xmax = GR.adjustlimits(xmin, xmax)
        majorx = 5
        xtick = GR.tick(xmin, xmax) / majorx
    else
        xtick = majorx = 1
    end
    if scale & GR.OPTION_Y_LOG == 0
        ymin, ymax = GR.adjustlimits(ymin, ymax)
        majory = 5
        ytick = GR.tick(ymin, ymax) / majory
    else
        ytick = majory = 1
    end
    if scale & GR.OPTION_FLIP_X == 0
        xorg = (xmin, xmax)
    else
        xorg = (xmax, xmin)
    end
    if scale & GR.OPTION_FLIP_Y == 0
        yorg = (ymin, ymax)
    else
        yorg = (ymax, ymin)
    end

    GR.setwindow(xmin, xmax, ymin, ymax)
    if haskey(plt.kvs, :backgroundcolor)
        GR.savestate()
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.setfillcolorind(plt.kvs[:backgroundcolor])
        GR.fillrect(xmin, xmax, ymin, ymax)
        GR.restorestate()
    end
    GR.setscale(scale)

    GR.setlinecolorind(1)
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    GR.setlinewidth(1)
    charheight = max(0.018 * diag, 0.01)
    GR.setcharheight(charheight)
    ticksize = 0.0075 * diag
    GR.grid(xtick, ytick, 0, 0, majorx, majory)
    GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
    GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)

    if haskey(plt.kvs, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.text(0.5, min(ratio, 1), plt.kvs[:title])
        GR.restorestate()
    end
    if haskey(plt.kvs, :xlabel)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_BOTTOM)
        GR.text(0.5, 0, plt.kvs[:xlabel])
        GR.restorestate()
    end
    if haskey(plt.kvs, :ylabel)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.setcharup(-1, 0)
        GR.text(0, 0.5 * (viewport[3] + viewport[4]), plt.kvs[:ylabel])
        GR.restorestate()
    end

    GR.uselinespec(" ")
    for (x, y, spec) in plt.args
        GR.savestate()
        if kind == :line
            mask = GR.uselinespec(spec)
            mask in (0, 1, 3, 4, 5) && GR.polyline(x, y)
            mask & 0x02 != 0 && GR.polymarker(x, y)
        elseif kind == :hist
            x, y, spec = plt.args[1]
            for i = 2:length(y)
                GR.setfillcolorind(989)
                GR.setfillintstyle(GR.INTSTYLE_SOLID)
                GR.fillrect(x[i-1], x[i], ymin, y[i])
                GR.setfillcolorind(1)
                GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
                GR.fillrect(x[i-1], x[i], ymin, y[i])
                end
        end
        GR.restorestate()
    end

    if haskey(plt.kvs, :labels)
        num_labels = length(plt.kvs[:labels])
        GR.savestate()
        GR.selntran(0)
        GR.setscale(0)
        w = 0
        for label in plt.kvs[:labels]
          tbx, tby = GR.inqtext(0, 0, label)
          w = max(w, tbx[3])
        end
        px = viewport[2] - 0.05 - w
        py = viewport[4] - 0.06
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.setfillcolorind(0)
        GR.fillrect(px - 0.08, px + w + 0.02, py + 0.03, py - 0.03 * num_labels)
        GR.setlinetype(1)
        GR.setlinecolorind(1)
        GR.setlinewidth(1)
        GR.drawrect(px - 0.08, px + w + 0.02, py + 0.03, py - 0.03 * num_labels)
        i = 0
        GR.uselinespec(" ")
        for (x, y, spec) in plt.args
            GR.savestate()
            mask = GR.uselinespec(spec)
            mask in (0, 1, 3, 4, 5) && GR.polyline([px - 0.07, px - 0.01], [py, py])
            mask & 0x02 != 0 && GR.polymarker([px - 0.06, px - 0.02], [py, py])
            GR.restorestate()
            GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
            if i < num_labels
                i += 1
                GR.text(px, py, plt.kvs[:labels][i])
            end
            py -= 0.03
        end
        GR.selntran(1)
        GR.restorestate()
    end
end

function plot_args(args)
    args = Any[args...]
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

    pltargs = Any[]

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
            push!(pltargs, (x, y, spec))
        end
    end

    pltargs
end

function minmax()
    xmin = ymin = typemax(Float64)
    xmax = ymax = typemin(Float64)
    for (x, y, spec) in plt.args
        xmin = min(minimum(x), xmin)
        xmax = max(maximum(x), xmax)
        ymin = min(minimum(y), ymin)
        ymax = max(maximum(y), ymax)
    end
    plt.kvs[:xrange] = xmin, xmax
    plt.kvs[:yrange] = ymin, ymax
end

function plot(args::PlotArg...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args)
    minmax()

    GR.clearws()

    plot_data()

    GR.updatews()
    if GR.isinline()
        return GR.show()
    end
end

function histogram(X; kv...)
    merge!(plt.kvs, Dict(kv))

    h = Base.hist(X)
    x, y = float(collect(h[1])), float(h[2])
    plt.args = [(x, y, "")]
    minmax()

    GR.clearws()

    plot_data(kind=:hist)

    GR.updatews()
    if GR.isinline()
        return GR.show()
    end
end

function title(s)
    plot_data(title=s)
end

function xlabel(s)
    plot_data(xlabel=s)
end

function ylabel(s)
    plot_data(ylabel=s)
end

function legend(args::AbstractString...; kv...)
    plot_data(labels=args)
end

function savefig(filename)
    GR.beginprint(filename)
    plot_data()
    GR.endprint()
end

function plot2d(x, y;
                bgcolor=0,
                viewport=(0.15, 0.95, 0.1, 0.7),
                window=(-1, 1, -1, 1),
                scale=0,                       # ignored
                grid=true,                     # ignored
                linetype=GR.LINETYPE_SOLID,    # ignored
                markertype=GR.MARKERTYPE_DOT,  # ignored
                clear=true,
                update=true)

    println("plot2d: This function is deprecated; use plot() instead")

    kv = Dict()
    kv[:backgroundcolor] = bgcolor
    kv[:viewport] = viewport
    kv[:xrange] = (window[1], window[2])
    kv[:yrange] = (window[3], window[4])

    if clear
        GR.clearws()
    end

    plt.args = [(x, y, "")]
    plt.kvs = kv

    plot_data()

    if update
        GR.updatews()
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
