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

@compat typealias PlotArg Union{AbstractString, AbstractVector, AbstractMatrix, Function}

const gr3 = GR.gr3

const plot_kind = [:line, :scatter, :hist, :contour, :contourf, :wireframe, :surface, :plot3]

const arg_fmt = [:xys, :xyac, :xyzc]

type PlotObject
    args
    kvs
end

function Figure(width=600, height=450)
    args = @_tuple(Any)
    kvs = Dict()
    kvs[:size] = (width, height)
    kvs[:ax] = false
    kvs[:subplot] = [0, 1, 0, 1]
    kvs[:clear] = true
    kvs[:update] = true
    PlotObject(args, kvs)
end

plt = Figure()

isrowvec(x::AbstractArray) = ndims(x) == 2 && size(x, 1) == 1 && size(x, 2) > 1

isvector(x::AbstractVector) = true
isvector(x::AbstractMatrix) = size(x, 1) == 1

function set_viewport(kind, subplot)
    mwidth, mheight, width, height = GR.inqdspsize()
    if haskey(plt.kvs, :figsize)
        w = 0.0254 *  width * plt.kvs[:figsize][1] / mwidth
        h = 0.0254 * height * plt.kvs[:figsize][2] / mheight
    else
        w, h = plt.kvs[:size]
    end
    viewport = zeros(4)
    vp = float(subplot)
    if w > h
        ratio = float(h) / w
        msize = mwidth * w / width
        GR.setwsviewport(0, msize, 0, msize * ratio)
        GR.setwswindow(0, 1, 0, ratio)
        vp[3] *= ratio
        vp[4] *= ratio
    else
        ratio = float(w) / h
        msize = mheight * h / height
        GR.setwsviewport(0, msize * ratio, 0, msize)
        GR.setwswindow(0, ratio, 0, 1)
        vp[1] *= ratio
        vp[2] *= ratio
    end
    viewport[1] = vp[1] + 0.125 * (vp[2] - vp[1])
    viewport[2] = vp[1] + 0.925 * (vp[2] - vp[1])
    viewport[3] = vp[3] + 0.125 * (vp[4] - vp[3])
    viewport[4] = vp[3] + 0.925 * (vp[4] - vp[3])

    if w > h
        viewport[3] += (1 - (subplot[4] - subplot[3])^2) * 0.02
    end
    if kind in (:wireframe, :surface, :plot3)
        viewport[2] -= 0.0525
    end
    if kind in (:contour, :contourf, :surface)
        viewport[2] -= 0.1
    end
    GR.setviewport(viewport[1], viewport[2], viewport[3], viewport[4])

    plt.kvs[:viewport] = viewport
    plt.kvs[:vp] = vp
    plt.kvs[:ratio] = ratio

    if haskey(plt.kvs, :backgroundcolor)
        GR.savestate()
        GR.selntran(0)
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.setfillcolorind(plt.kvs[:backgroundcolor])
        if w > h
          GR.fillrect(subplot[1], subplot[2],
                      ratio * subplot[3], ratio * subplot[4])
        else
          GR.fillrect(ratio * subplot[1], ratio * subplot[2],
                      subplot[3], subplot[4])
        end
        GR.selntran(1)
        GR.restorestate()
    end
end

function minmax()
    xmin = ymin = zmin = typemax(Float64)
    xmax = ymax = zmax = typemin(Float64)
    for (x, y, z, c, spec) in plt.args
        xmin = min(minimum(x), xmin)
        xmax = max(maximum(x), xmax)
        ymin = min(minimum(y), ymin)
        ymax = max(maximum(y), ymax)
        if z != Void
            zmin = min(minimum(z), zmin)
            zmax = max(maximum(z), zmax)
        end
    end
    if haskey(plt.kvs, :xlim)
        plt.kvs[:xrange] = plt.kvs[:xlim]
    else
        plt.kvs[:xrange] = xmin, xmax
    end
    if haskey(plt.kvs, :ylim)
        plt.kvs[:yrange] = plt.kvs[:ylim]
    else
        plt.kvs[:yrange] = ymin, ymax
    end
    if haskey(plt.kvs, :zlim)
        plt.kvs[:zrange] = plt.kvs[:zlim]
    else
        plt.kvs[:zrange] = zmin, zmax
    end
end

function set_window(kind)
    scale = 0
    get(plt.kvs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
    get(plt.kvs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
    get(plt.kvs, :zlog, false) && (scale |= GR.OPTION_Z_LOG)
    get(plt.kvs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
    get(plt.kvs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)
    get(plt.kvs, :zflip, false) && (scale |= GR.OPTION_FLIP_Z)

    minmax()

    if kind in (:wireframe, :surface, plot3)
        major_count = 2
    else
        major_count = 5
    end

    xmin, xmax = plt.kvs[:xrange]
    if scale & GR.OPTION_X_LOG == 0
        xmin, xmax = GR.adjustlimits(xmin, xmax)
        majorx = major_count
        xtick = GR.tick(xmin, xmax) / majorx
    else
        xtick = majorx = 1
    end
    if scale & GR.OPTION_FLIP_X == 0
        xorg = (xmin, xmax)
    else
        xorg = (xmax, xmin)
    end
    plt.kvs[:xaxis] = xtick, xorg, majorx

    ymin, ymax = plt.kvs[:yrange]
    if kind == :hist && !haskey(plt.kvs, :ylim)
        ymin = 0
    end
    if scale & GR.OPTION_Y_LOG == 0
        ymin, ymax = GR.adjustlimits(ymin, ymax)
        majory = major_count
        ytick = GR.tick(ymin, ymax) / majory
    else
        ytick = majory = 1
    end
    if scale & GR.OPTION_FLIP_Y == 0
        yorg = (ymin, ymax)
    else
        yorg = (ymax, ymin)
    end
    plt.kvs[:yaxis] = ytick, yorg, majory

    if kind in (:wireframe, :surface, :plot3)
        zmin, zmax = plt.kvs[:zrange]
        if scale & GR.OPTION_Y_LOG == 0
            zmin, zmax = GR.adjustlimits(zmin, zmax)
            majorz = major_count
            ztick = GR.tick(zmin, zmax) / majorz
        else
            ztick = majorz = 1
        end
        if scale & GR.OPTION_FLIP_Z == 0
            zorg = (zmin, zmax)
        else
            zorg = (zmax, zmin)
        end
        plt.kvs[:zaxis] = ztick, zorg, majorz
    end

    plt.kvs[:window] = xmin, xmax, ymin, ymax
    GR.setwindow(xmin, xmax, ymin, ymax)
    if kind in (:wireframe, :surface, :plot3)
        rotation = get(plt.kvs, :rotation, 40)
        tilt = get(plt.kvs, :tilt, 70)
        GR.setspace(zmin, zmax, rotation, tilt)
    end

    plt.kvs[:scale] = scale
    GR.setscale(scale)
end

function draw_axes(kind, pass=1)
    viewport = plt.kvs[:viewport]
    vp = plt.kvs[:vp]
    ratio = plt.kvs[:ratio]
    xtick, xorg, majorx = plt.kvs[:xaxis]
    ytick, yorg, majory = plt.kvs[:yaxis]

    GR.setlinecolorind(1)
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    GR.setlinewidth(1)
    charheight = max(0.018 * diag, 0.012)
    GR.setcharheight(charheight)
    ticksize = 0.0075 * diag
    if kind in (:wireframe, :surface, :plot3)
        ztick, zorg, majorz = plt.kvs[:zaxis]
        if pass == 1
            GR.grid3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], 2, 0, 2)
            GR.grid3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, 2, 0)
        else
            GR.axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], majorx, 0, majorz, -ticksize)
            GR.axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, majory, 0, ticksize)
        end
    else
        GR.grid(xtick, ytick, 0, 0, majorx, majory)
        GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
        GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
    end

    if haskey(plt.kvs, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.textext(0.5 * (viewport[1] + viewport[2]), vp[4], plt.kvs[:title])
        GR.restorestate()
    end
    if kind in (:wireframe, :surface, :plot3)
        xlabel = get(plt.kvs, :xlabel, "")
        ylabel = get(plt.kvs, :ylabel, "")
        zlabel = get(plt.kvs, :zlabel, "")
        GR.titles3d(xlabel, ylabel, zlabel)
    else
        if haskey(plt.kvs, :xlabel)
            GR.savestate()
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_BOTTOM)
            GR.textext(0.5 * (viewport[1] + viewport[2]), vp[3] + 0.5 * charheight, plt.kvs[:xlabel])
            GR.restorestate()
        end
        if haskey(plt.kvs, :ylabel)
            GR.savestate()
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
            GR.setcharup(-1, 0)
            GR.textext(vp[1] + 0.5 * charheight, 0.5 * (viewport[3] + viewport[4]), plt.kvs[:ylabel])
            GR.restorestate()
        end
    end
end

function draw_legend()
    viewport = plt.kvs[:viewport]
    num_labels = length(plt.kvs[:labels])
    GR.savestate()
    GR.selntran(0)
    GR.setscale(0)
    w = 0
    for label in plt.kvs[:labels]
        tbx, tby = GR.inqtextext(0, 0, label)
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
    for (x, y, z, c, spec) in plt.args
        GR.savestate()
        mask = GR.uselinespec(spec)
        mask in (0, 1, 3, 4, 5) && GR.polyline([px - 0.07, px - 0.01], [py, py])
        mask & 0x02 != 0 && GR.polymarker([px - 0.06, px - 0.02], [py, py])
        GR.restorestate()
        GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
        if i < num_labels
            i += 1
            GR.textext(px, py, plt.kvs[:labels][i])
        end
        py -= 0.03
    end
    GR.selntran(1)
    GR.restorestate()
end

function colorbar(off=0, colors=256)
    GR.savestate()
    viewport = plt.kvs[:viewport]
    zmin, zmax = plt.kvs[:zrange]
    GR.setwindow(0, 1, zmin, zmax)
    GR.setviewport(viewport[2] + 0.02 + off, viewport[2] + 0.05 + off,
                   viewport[3], viewport[4])
    l = zeros(Int32, 1, colors)
    l[1,:] = round(Int32, linspace(1000, 1255, colors))
    GR.cellarray(0, 1, zmax, zmin, 1, colors, l)
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    charheight = max(0.016 * diag, 0.012)
    GR.setcharheight(charheight)
    if plt.kvs[:scale] & GR.OPTION_Z_LOG == 0
        ztick = 0.5 * GR.tick(zmin, zmax)
        GR.axes(0, ztick, 1, zmin, 0, 1, 0.005)
    else
        GR.setscale(GR.OPTION_Y_LOG)
        GR.axes(0, 2, 1, zmin, 0, 1, 0.005)
    end
    GR.restorestate()
end

function figure(; kv...)
    global plt
    plt = Figure()
    merge!(plt.kvs, Dict(kv))
    plt
end

function hold(flag)
    plt.kvs[:ax] = flag
    plt.kvs[:clear] = !flag
end

function subplot(nr, nc, p)
    xmin, xmax, ymin, ymax = 1, 0, 1, 0
    for i in collect(p)
        r = nr - div(i-1, nc)
        c = (i-1) % nc + 1
        xmin = min(xmin, (c-1)/nc)
        xmax = max(xmax, c/nc)
        ymin = min(ymin, (r-1)/nr)
        ymax = max(ymax, r/nr)
    end
    plt.kvs[:subplot] = [xmin, xmax, ymin, ymax]
    plt.kvs[:clear] = collect(p)[1] == 1
    plt.kvs[:update] = collect(p)[end] == nr * nc
end

function plot_data(; kv...)
    merge!(plt.kvs, Dict(kv))

    if plt.args == @_tuple(Any)
        return
    end
    kind = get(plt.kvs, :kind, :line)

    plt.kvs[:clear] && GR.clearws()

    if !plt.kvs[:ax]
        set_viewport(kind, plt.kvs[:subplot])
        set_window(kind)
        draw_axes(kind)
    end

    if haskey(plt.kvs, :colormap)
        GR.setcolormap(plt.kvs[:colormap])
    else
        GR.setcolormap(GR.COLORMAP_COOLWARM)
    end

    GR.uselinespec(" ")
    for (x, y, z, c, spec) in plt.args
        GR.savestate()
        if haskey(plt.kvs, :alpha)
            GR.settransparency(plt.kvs[:alpha])
        end
        if kind == :line
            mask = GR.uselinespec(spec)
            mask in (0, 1, 3, 4, 5) && GR.polyline(x, y)
            mask & 0x02 != 0 && GR.polymarker(x, y)
        elseif kind == :scatter
            GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
            if z != Void || c != Void
                if c != Void
                    c = (c - minimum(c)) / (maximum(c) - minimum(c))
                    cind = round(Int64, 1000 + c * 255)
                end
                for i in 1:length(x)
                    (z != Void) && GR.setmarkersize(z[i] / 100.0)
                    (c != Void )&& GR.setmarkercolorind(cind[i])
                    GR.polymarker([x[i]], [y[i]])
                end
            else
                GR.polymarker(x, y)
            end
        elseif kind == :hist
            ymin = plt.kvs[:window][3]
            for i = 2:length(y)
                GR.setfillcolorind(989)
                GR.setfillintstyle(GR.INTSTYLE_SOLID)
                GR.fillrect(x[i-1], x[i], ymin, y[i])
                GR.setfillcolorind(1)
                GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
                GR.fillrect(x[i-1], x[i], ymin, y[i])
            end
        elseif kind == :contour
            zmin, zmax = plt.kvs[:zrange]
            GR.setspace(zmin, zmax, 0, 90)
            h = linspace(zmin, zmax, 20)
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
            end
            GR.contour(x, y, h, z, 1000)
            colorbar(0, 20)
        elseif kind == :contourf
            xmin, xmax = plt.kvs[:xrange]
            ymin, ymax = plt.kvs[:yrange]
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
                z = reshape(z, 200, 200)
            end
            if plt.kvs[:scale] & GR.OPTION_Z_LOG != 0
                z = log(z)
            end
            width, height = size(z)
            data = (z - minimum(z)) / (maximum(z) - minimum(z))
            data = round(Int32, 1000 + data * 255)
            GR.cellarray(xmin, xmax, ymax, ymin, width, height, data)
            colorbar()
        elseif kind == :wireframe
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 50, 50)
            end
            GR.setfillcolorind(0)
            GR.surface(x, y, z, GR.OPTION_FILLED_MESH)
            draw_axes(kind, 2)
        elseif kind == :surface
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
            end
            if get(plt.kvs, :accelerate, true)
                GR.gr3.surface(x, y, z, GR.OPTION_COLORED_MESH)
            else
                GR.surface(x, y, z, GR.OPTION_COLORED_MESH)
            end
            draw_axes(kind, 2)
            colorbar(0.05)
        elseif kind == :plot3
            GR.polyline3d(x, y, z)
            draw_axes(kind, 2)
        end
        GR.restorestate()
    end

    if kind in (:line, :scatter) && haskey(plt.kvs, :labels)
        draw_legend()
    end

    if plt.kvs[:update]
        GR.updatews()
        if GR.isinline()
            return GR.show()
        end
    end
end

function plot_args(args; fmt=:xys)
    args = Any[args...]
    parsed_args = Any[]

    while length(args) > 0
        local x, y, z, c
        a = shift!(args)
        if isa(a, AbstractVecOrMat)
            elt = eltype(a)
            if elt <: Complex
                x = real(a)
                y = imag(a)
                z = Void
                c = Void
            elseif elt <: Real
                if fmt == :xys
                    if length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || typeof(args[1]) == Function)
                        x = a
                        y = shift!(args)
                        z = Void
                        c = Void
                    else
                        y = a
                        n = isrowvec(y) ? size(y, 2) : size(y, 1)
                        x = linspace(1, n, n)
                        z = Void
                        c = Void
                    end
                elseif fmt == :xyac || fmt == :xyzc
                    if length(args) >= 3 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || typeof(args[2]) == Function) &&
                       (isa(args[3], AbstractVecOrMat) && eltype(args[3]) <: Real || typeof(args[3]) == Function)
                        x = a
                        y = shift!(args)
                        z = shift!(args)
                        c = shift!(args)
                    elseif length(args) >= 2 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || typeof(args[2]) == Function)
                        x = a
                        y = shift!(args)
                        z = shift!(args)
                        c = Void
                    elseif fmt == :xyac && length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || typeof(args[1]) == Function)
                        x = a
                        y = shift!(args)
                        z = Void
                        c = Void
                    elseif fmt == :xyzc && length(args) == 0
                        z = a
                        nx, ny = size(z)
                        x = linspace(1, nx, nx)
                        y = linspace(1, ny, ny)
                        c = Void
                    end
                end
            else
                error("expected Real or Complex")
            end
        else
            error("expected array or function")
        end
        spec = ""
        if fmt == :xys && length(args) > 0 && isa(args[1], AbstractString)
            spec = shift!(args)
        end
        push!(parsed_args, (x, y, z, c, spec))
    end

    pltargs = Any[]

    for arg in parsed_args
        x, y, z, c, spec = arg

        isa(x, UnitRange) && (x = collect(x))
        isa(y, UnitRange) && (y = collect(y))
        isa(z, UnitRange) && (z = collect(z))
        isa(c, UnitRange) && (c = collect(c))

        isvector(x) && (x = vec(x))
        if typeof(y) == Function
            y = [y(a) for a in x]
        else
            isvector(y) && (y = vec(y))
        end
        if z != Void
            if fmt == :xyzc && typeof(z) == Function
                z = [z(a,b) for a in x, b in y]
            else
                isvector(z) && (z = vec(z))
            end
        end
        if c != Void
            isvector(c) && (c = vec(c))
        end

        local xyzc
        if z == Void
            if isa(x, AbstractVector) && isa(y, AbstractVector)
                xyzc = [ (x, y, z, c) ]
            elseif isa(x, AbstractVector)
                xyzc = length(x) == size(y, 1) ?
                       [ (x, sub(y,:,j), z, c) for j = 1:size(y, 2) ] :
                       [ (x, sub(y,i,:), z, c) for i = 1:size(y, 1) ]
            elseif isa(y, AbstractVector)
                xyzc = size(x, 1) == length(y) ?
                       [ (sub(x,:,j), y, z, c) for j = 1:size(x, 2) ] :
                       [ (sub(x,i,:), y, z, c) for i = 1:size(x, 1) ]
            else
                @assert size(x) == size(y)
                xyzc = [ (sub(x,:,j), sub(y,:,j), z, c) for j = 1:size(y, 2) ]
            end
        elseif isa(x, AbstractVector) && isa(y, AbstractVector) &&
               (isa(z, AbstractVector) || typeof(z) == Array{Float64,2} ||
                typeof(z) == Array{Int32,2} || typeof(z) == Array{Any,2})
            xyzc = [ (x, y, z, c) ]
        end
        for (x, y, z, c) in xyzc
            push!(pltargs, (x, y, z, c, spec))
        end
    end

    pltargs
end

function plot(args::PlotArg...; kv...)
    merge!(plt.kvs, Dict(kv))

    if plt.kvs[:ax]
        plt.args = append!(plt.args, plot_args(args))
    else
        plt.args = plot_args(args)
    end

    plot_data(kind=:line)
end

function oplot(args::PlotArg...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = append!(plt.args, plot_args(args))

    plot_data(kind=:line)
end

function scatter(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyac)

    plot_data(kind=:scatter)
end

function histogram(x; kv...)
    merge!(plt.kvs, Dict(kv))

    h = Base.hist(x)
    x, y = float(collect(h[1])), float(h[2])
    plt.args = [(x, y, Void, Void, "")]

    plot_data(kind=:hist)
end

function contour(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data(kind=:contour)
end

function contourf(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data(kind=:contourf)
end

function wireframe(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data(kind=:wireframe)
end

function surface(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data(kind=:surface)
end

function plot3(args...; kv...)
    merge!(plt.kvs, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data(kind=:plot3)
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

function xlim(a)
    plot_data(xlim=a)
end

function ylim(a)
    plot_data(ylim=a)
end

function savefig(filename)
    GR.beginprint(filename)
    plot_data()
    GR.endprint()
end

function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T})
    m, n = length(vy), length(vx)
    vx = reshape(vx, 1, n)
    vy = reshape(vy, m, 1)
    (repmat(vx, m, 1), repmat(vy, 1, n))
end

function peaks(n=49)
    x = linspace(-2.5, 2.5, n)
    y = x
    x, y = meshgrid(x, y)
    3*(1-x).^2.*exp(-(x.^2) - (y+1).^2) - 10*(x/5 - x.^3 - y.^5).*exp(-x.^2-y.^2) - 1/3*exp(-(x+1).^2 - y.^2)
end

function imshow(I; kv...)
    merge!(plt.kvs, Dict(kv))

    if isa(I, AbstractString)
        width, height, data = GR.readimage(I)
    else
        width, height = size(I)
        data = (float(I) - minimum(I)) / (maximum(I) - minimum(I))
        data = round(Int32, 1000 + data * 255)
    end

    plt.kvs[:clear] && GR.clearws()

    if !plt.kvs[:ax]
        set_viewport(:line, plt.kvs[:subplot])
    end
    viewport = plt.kvs[:viewport]
    vp = plt.kvs[:vp]

    if width  * (viewport[4] - viewport[3]) <
       height * (viewport[2] - viewport[1])
        ratio = float(width) / height
        xmin = max(0.5 * (viewport[2] - ratio), viewport[1])
        xmax = min(xmin + ratio, viewport[2])
        ymin = viewport[3]
        ymax = viewport[4]
    else
        ratio = float(height) / width
        xmin = viewport[1]
        xmax = viewport[2]
        ymin = max(0.5 * (viewport[4] - ratio), viewport[3])
        ymax = min(ymin + ratio, viewport[4])
    end

    if haskey(plt.kvs, :cmap)
        GR.setcolormap(plt.kvs[:cmap])
    else
        GR.setcolormap(1)
    end

    GR.selntran(0)
    if isa(I, AbstractString)
        GR.drawimage(xmin, xmax, ymin, ymax, width, height, data)
    else
        GR.cellarray(xmin, xmax, ymin, ymax, width, height, data)
    end

    if haskey(plt.kvs, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        GR.textext(0.5 * (viewport[1] + viewport[2]), vp[4], plt.kvs[:title])
        GR.restorestate()
    end
    GR.selntran(1)

    if plt.kvs[:update]
        GR.updatews()
        if GR.isinline()
            return GR.show()
        end
    end
end

end # module
