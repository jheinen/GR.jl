module jlgr

import GR

const None = Union{}

macro _tuple(t)
    :( Tuple{$t} )
end

const PlotArg = Union{AbstractString, AbstractVector, AbstractMatrix, Function}

const gr3 = GR.gr3

const plot_kind = [:line, :scatter, :stem, :hist, :contour, :contourf, :hexbin, :heatmap, :wireframe, :surface, :plot3, :scatter3, :imshow, :isosurface, :polar, :trisurf, :tricont]

const arg_fmt = [:xys, :xyac, :xyzc]

const kw_args = [:accelerate, :alpha, :backgroundcolor, :color, :colormap, :figsize, :isovalue, :labels, :location, :nbins, :rotation, :size, :tilt, :title, :xflip, :xlabel, :xlim, :xlog, :yflip, :ylabel, :ylim, :ylog, :zflip, :zlim, :zlog]

const colors = [
    [0xffffff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0x00ffff, 0xffff00, 0xff00ff] [0x282c34, 0xd7dae0, 0xcb4e42, 0x99c27c, 0x85a9fc, 0x5ab6c1, 0xd09a6a, 0xc57bdb] [0xfdf6e3, 0x657b83, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682] [0x002b36, 0x839496, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682]
    ]

const distinct_cmap = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

type PlotObject
    obj
    args
    kvs
end

function Figure(width=600, height=450)
    obj = Dict()
    args = @_tuple(Any)
    kvs = Dict()
    kvs[:size] = (width, height)
    kvs[:ax] = false
    kvs[:subplot] = [0, 1, 0, 1]
    kvs[:clear] = true
    kvs[:update] = true
    PlotObject(obj, args, kvs)
end

function gcf()
    plt.kvs
end

plt = Figure()
ctx = Dict()
scheme = 0
background = 0xffffff

isrowvec(x::AbstractArray) = ndims(x) == 2 && size(x, 1) == 1 && size(x, 2) > 1

isvector(x::AbstractVector) = true
isvector(x::AbstractMatrix) = size(x, 1) == 1

function set_viewport(kind, subplot)
    mwidth, mheight, width, height = GR.inqdspsize()
    if haskey(plt.kvs, :figsize)
        w = 0.0254 *  width * plt.kvs[:figsize][1] / mwidth
        h = 0.0254 * height * plt.kvs[:figsize][2] / mheight
    else
        dpi = width / mwidth * 0.0254
        if dpi > 200
            w, h = [x * dpi / 100 for x in plt.kvs[:size]]
        else
            w, h = plt.kvs[:size]
        end
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
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf)
        extent = min(vp[2] - vp[1], vp[4] - vp[3])
        vp1 = 0.5 * (vp[1] + vp[2] - extent)
        vp2 = 0.5 * (vp[1] + vp[2] + extent)
        vp3 = 0.5 * (vp[3] + vp[4] - extent)
        vp4 = 0.5 * (vp[3] + vp[4] + extent)
    else
        vp1, vp2, vp3, vp4 = vp
    end
    viewport[1] = vp1 + 0.125 * (vp2 - vp1)
    viewport[2] = vp1 + 0.925 * (vp2 - vp1)
    viewport[3] = vp3 + 0.125 * (vp4 - vp3)
    viewport[4] = vp3 + 0.925 * (vp4 - vp3)

    if kind in (:contour, :contourf, :hexbin, :heatmap, :surface, :trisurf)
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

    if kind == :polar
        xmin, xmax, ymin, ymax = viewport
        xcenter = 0.5 * (xmin + xmax)
        ycenter = 0.5 * (ymin + ymax)
        r = 0.5 * min(xmax - xmin, ymax - ymin)
        GR.setviewport(xcenter - r, xcenter + r, ycenter - r, ycenter + r)
    end
end

function fix_minmax(a, b)
    if a == b
        a -= a != 0 ? 0.1 * a : 0.1
        b += b != 0 ? 0.1 * b : 0.1
    end
    a, b
end

function given(a)
    a != Void && a != "Void"
end

function minmax()
    xmin = ymin = zmin = typemax(Float64)
    xmax = ymax = zmax = typemin(Float64)
    for (x, y, z, c, spec) in plt.args
        if given(x)
            xmin = min(minimum(x), xmin)
            xmax = max(maximum(x), xmax)
        else
            xmin, xmax = 0, 1
        end
        if given(y)
            ymin = min(minimum(y), ymin)
            ymax = max(maximum(y), ymax)
        else
            ymin, ymax = 0, 1
        end
        if given(z)
            zmin = min(minimum(z), zmin)
            zmax = max(maximum(z), zmax)
        end
    end
    xmin, xmax = fix_minmax(xmin, xmax)
    ymin, ymax = fix_minmax(ymin, ymax)
    zmin, zmax = fix_minmax(zmin, zmax)
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
    if kind != :polar
        get(plt.kvs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
        get(plt.kvs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
        get(plt.kvs, :zlog, false) && (scale |= GR.OPTION_Z_LOG)
        get(plt.kvs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
        get(plt.kvs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)
        get(plt.kvs, :zflip, false) && (scale |= GR.OPTION_FLIP_Z)
    end

    minmax()

    if kind in (:wireframe, :surface, :plot3, :scatter3, :polar, :trisurf)
        major_count = 2
    else
        major_count = 5
    end

    xmin, xmax = plt.kvs[:xrange]
    if scale & GR.OPTION_X_LOG == 0
        if !haskey(plt.kvs, :xlim)
            xmin, xmax = GR.adjustlimits(xmin, xmax)
        end
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
    if kind in (:stem, :hist) && !haskey(plt.kvs, :ylim)
        ymin = 0
    end
    if scale & GR.OPTION_Y_LOG == 0
        if !haskey(plt.kvs, :ylim)
            ymin, ymax = GR.adjustlimits(ymin, ymax)
        end
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

    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf)
        zmin, zmax = plt.kvs[:zrange]
        if scale & GR.OPTION_Z_LOG == 0
            if !haskey(plt.kvs, :zlim)
                zmin, zmax = GR.adjustlimits(zmin, zmax)
            end
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
    if kind != :polar
        GR.setwindow(xmin, xmax, ymin, ymax)
    else
        GR.setwindow(-1, 1, -1, 1)
    end
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf)
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
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf)
        ztick, zorg, majorz = plt.kvs[:zaxis]
        if pass == 1
            GR.grid3d(xtick, 0, ztick, xorg[1], yorg[2], zorg[1], 2, 0, 2)
            GR.grid3d(0, ytick, 0, xorg[1], yorg[2], zorg[1], 0, 2, 0)
        else
            GR.axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], majorx, 0, majorz, -ticksize)
            GR.axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, majory, 0, ticksize)
        end
    else
        if kind == :heatmap
            ticksize = -ticksize
        else
            GR.grid(xtick, ytick, 0, 0, majorx, majory)
        end
        GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
        GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
    end

    if haskey(plt.kvs, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        text(0.5 * (viewport[1] + viewport[2]), vp[4], plt.kvs[:title])
        GR.restorestate()
    end
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf)
        xlabel = get(plt.kvs, :xlabel, "")
        ylabel = get(plt.kvs, :ylabel, "")
        zlabel = get(plt.kvs, :zlabel, "")
        GR.titles3d(xlabel, ylabel, zlabel)
    else
        if haskey(plt.kvs, :xlabel)
            GR.savestate()
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_BOTTOM)
            text(0.5 * (viewport[1] + viewport[2]), vp[3] + 0.5 * charheight, plt.kvs[:xlabel])
            GR.restorestate()
        end
        if haskey(plt.kvs, :ylabel)
            GR.savestate()
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
            GR.setcharup(-1, 0)
            text(vp[1] + 0.5 * charheight, 0.5 * (viewport[3] + viewport[4]), plt.kvs[:ylabel])
            GR.restorestate()
        end
    end
end

function draw_polar_axes()
    viewport = plt.kvs[:viewport]
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    charheight = max(0.018 * diag, 0.012)

    window = plt.kvs[:window]
    rmin, rmax = window[3], window[4]

    GR.savestate()
    GR.setcharheight(charheight)
    GR.setlinetype(GR.LINETYPE_SOLID)

    tick = 0.5 * GR.tick(rmin, rmax)
    n = round(Int, (rmax - rmin) / tick + 0.5)
    for i in 0:n
        r = float(i) / n
        if i % 2 == 0
            GR.setlinecolorind(88)
            if i > 0
                GR.drawarc(-r, r, -r, r, 0, 359)
            end
            GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
            x, y = GR.wctondc(0.05, r)
            GR.text(x, y, string(signif(rmin + i * tick, 12)))
        else
            GR.setlinecolorind(90)
            GR.drawarc(-r, r, -r, r, 0, 359)
        end
    end
    for alpha in 0:45:315
        a = alpha + 90
        sinf = sin(a * π / 180)
        cosf = cos(a * π / 180)
        GR.polyline([sinf, 0], [cosf, 0])
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)
        x, y = GR.wctondc(1.1 * sinf, 1.1 * cosf)
        GR.textext(x, y, string(alpha, "^o"))
    end
    GR.restorestate()
end

function inqtext(x, y, s)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.inqtextext(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        GR.inqtextext(x, y, s)
    else
        GR.inqtext(x, y, s)
    end
end

function text(x, y, s)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.mathtex(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        GR.textext(x, y, s)
    else
        GR.text(x, y, s)
    end
end

function draw_legend()
    viewport = plt.kvs[:viewport]
    location = get(plt.kvs, :location, 1)
    num_labels = length(plt.kvs[:labels])
    GR.savestate()
    GR.selntran(0)
    GR.setscale(0)
    w = 0
    for label in plt.kvs[:labels]
        tbx, tby = GR.inqtextext(0, 0, label)
        w = max(w, tbx[3])
    end
    num_lines = length(plt.args)
    h = (num_lines + 1) * 0.03
    if location in (8, 9, 10)
        px = 0.5 * (viewport[1] + viewport[2] - w)
    elseif location in (2, 3, 6)
        px = viewport[1] + 0.11
    else
        px = viewport[2] - 0.05 - w
    end
    if location in (5, 6, 7, 10)
        py = 0.5 * (viewport[3] + viewport[4] + h) - 0.03
    elseif location in (3, 4, 8)
        py = viewport[3] + h
    else
        py = viewport[4] - 0.06
    end
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(0)
    GR.fillrect(px - 0.08, px + w + 0.02, py + 0.03, py - 0.03 * num_lines)
    GR.setlinetype(GR.LINETYPE_SOLID)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    GR.drawrect(px - 0.08, px + w + 0.02, py + 0.03, py - 0.03 * num_lines)
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
            text(px, py, plt.kvs[:labels][i])
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
    l[1,:] = Int[round(Int, _i) for _i in linspace(1000, 1255, colors)]
    GR.cellarray(0, 1, zmax, zmin, 1, colors, l)
    GR.setlinecolorind(1)
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    charheight = max(0.016 * diag, 0.012)
    GR.setcharheight(charheight)
    if get(plt.kvs, :zflip, false)
        options = (GR.inqscale() | GR.OPTION_FLIP_Y) & ~GR.OPTION_FLIP_X
        GR.setscale(options)
    end
    if plt.kvs[:scale] & GR.OPTION_Z_LOG == 0
        ztick = 0.5 * GR.tick(zmin, zmax)
        GR.axes(0, ztick, 1, zmin, 0, 1, 0.005)
    else
        GR.setscale(GR.OPTION_Y_LOG)
        GR.axes(0, 2, 1, zmin, 0, 1, 0.005)
    end
    GR.restorestate()
end

function colormap()
    rgb = zeros(256, 3)
    for colorind in 1:256
        color = GR.inqcolor(999 + colorind)
        rgb[colorind, 1] = float( color        & 0xff) / 255.0
        rgb[colorind, 2] = float((color >> 8)  & 0xff) / 255.0
        rgb[colorind, 3] = float((color >> 16) & 0xff) / 255.0
    end
    rgb
end

function to_rgba(value, cmap)
    if !isnan(value)
        r, g, b = cmap[round(Int, value * 255 + 1), :]
        a = 1.0
    else
        r, g, b, a = zeros(4)
    end
    round(Int, a * 255) << 24 + round(Int, b * 255) << 16 +
    round(Int, g * 255) << 8  + round(Int, r * 255)
end

function create_context(kind, dict)
    plt.kvs[:kind] = kind
    plt.obj = copy(plt.kvs)
    for (k, v) in dict
        if ! (k in kw_args)
            println("Invalid keyword: $k")
        end
    end
    merge!(plt.kvs, dict)
end

function restore_context()
    global ctx
    ctx = copy(plt.kvs)
    plt.kvs = copy(plt.obj)
end

function figure(; kv...)
    global plt
    plt = Figure()
    merge!(plt.kvs, Dict(kv))
    plt
end

function hold(flag)
    global ctx
    if plt.args != @_tuple(Any)
        plt.kvs[:ax] = flag
        plt.kvs[:clear] = !flag
        for k in (:window, :scale, :xaxis, :yaxis, :zaxis)
            if haskey(ctx, k)
                plt.kvs[k] = ctx[k]
            end
        end
    else
        println("Invalid hold state")
    end
    flag
end

function usecolorscheme(index)
    global scheme
    if 1 <= index <= 4
        scheme = index
    else
        println("Invalid color sheme")
    end
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

function plot_img(I)
    viewport = plt.kvs[:viewport]
    vp = plt.kvs[:vp]

    if isa(I, AbstractString)
        width, height, data = GR.readimage(I)
    else
        width, height = size(I)
        data = (float(I) - minimum(I)) / (maximum(I) - minimum(I))
        data = Int32[round(Int32, 1000 + _i * 255) for _i in data]
    end

    if width  * (viewport[4] - viewport[3]) <
        height * (viewport[2] - viewport[1])
        w = float(width) / height * (viewport[4] - viewport[3])
        xmin = max(0.5 * (viewport[1] + viewport[2] - w), viewport[1])
        xmax = min(0.5 * (viewport[1] + viewport[2] + w), viewport[2])
        ymin = viewport[3]
        ymax = viewport[4]
    else
        h = float(height) / width * (viewport[2] - viewport[1])
        xmin = viewport[1]
        xmax = viewport[2]
        ymin = max(0.5 * (viewport[4] + viewport[3] - h), viewport[3])
        ymax = min(0.5 * (viewport[4] + viewport[3] + h), viewport[4])
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
        text(0.5 * (viewport[1] + viewport[2]), vp[4], plt.kvs[:title])
        GR.restorestate()
    end
    GR.selntran(1)
end

function plot_iso(V)
    viewport = plt.kvs[:viewport]

    if viewport[4] - viewport[3] < viewport[2] - viewport[1]
        width = viewport[4] - viewport[3]
        centerx = 0.5 * (viewport[1] + viewport[2])
        xmin = max(centerx - 0.5 * width, viewport[1])
        xmax = min(centerx + 0.5 * width, viewport[2])
        ymin = viewport[3]
        ymax = viewport[4]
    else
        height = viewport[2] - viewport[1]
        centery = 0.5 * (viewport[3] + viewport[4])
        xmin = viewport[1]
        xmax = viewport[2]
        ymin = max(centery - 0.5 * height, viewport[3])
        ymax = min(centery + 0.5 * height, viewport[4])
    end

    GR.selntran(0)
if VERSION > v"0.6-"
    values = round.(UInt16, (V-minimum(V)) / (maximum(V)-minimum(V)) * (2^16-1))
else
    values = round(UInt16, (V-minimum(V)) / (maximum(V)-minimum(V)) * (2^16-1))
end
    nx, ny, nz = size(V)
    isovalue = get(plt.kvs, :isovalue, 0.5)
    rotation = get(plt.kvs, :rotation, 40) * π / 180.0
    tilt = get(plt.kvs, :tilt, 70) * π / 180.0
    r = 2.5
    gr3.clear()
    mesh = gr3.createisosurfacemesh(values, (2/(nx-1), 2/(ny-1), 2/(nz-1)),
                                    (-1., -1., -1.),
                                    round(Int64, isovalue * (2^16-1)))
    if haskey(plt.kvs, :color)
        color = plt.kvs[:color]
    else
        color = (0.0, 0.5, 0.8)
    end
    gr3.setbackgroundcolor(1, 1, 1, 0)
    gr3.drawmesh(mesh, 1, (0, 0, 0), (0, 0, 1), (0, 1, 0), color, (1, 1, 1))
    gr3.cameralookat(r*sin(tilt)*sin(rotation), r*cos(tilt), r*sin(tilt)*cos(rotation), 0, 0, 0, 0, 1, 0)
    gr3.drawimage(xmin, xmax, ymin, ymax, 500, 500, gr3.DRAWABLE_GKS)
    gr3.deletemesh(mesh)
    GR.selntran(1)
end

function plot_polar(θ, ρ)
    window = plt.kvs[:window]
    rmin, rmax = window[3], window[4]
    ρ = (ρ - rmin) / (rmax - rmin)
    n = length(ρ)
    x, y = zeros(n), zeros(n)
    for i in 1:n
        x[i] = ρ[i] * cos(θ[i])
        y[i] = ρ[i] * sin(θ[i])
    end
    GR.polyline(x, y)
end

function RGB(color)
    rgb = zeros(3)
    rgb[1] = float((color >> 16) & 0xff) / 255.0
    rgb[2] = float((color >> 8)  & 0xff) / 255.0
    rgb[3] = float( color        & 0xff) / 255.0
    rgb
end

function plot_data(flag=true)
    global scheme, background

    if plt.args == @_tuple(Any)
        return
    end

    if flag && GR.displayname() != None
        handle = connect(GR.displayname(), 8001)
        io = IOBuffer()
        serialize(io, Dict("kvs" => plt.kvs, "args" => plt.args))
        write(handle, io.data)
        close(handle)
        return
    end

    kind = get(plt.kvs, :kind, :line)

    plt.kvs[:clear] && GR.clearws()

    if scheme != 0
        for colorind in 1:8
            color = colors[colorind, scheme]
            if colorind == 1
                background = color
            end
            r, g, b = RGB(color)
            GR.setcolorrep(colorind - 1, r, g, b)
            if scheme != 1
                GR.setcolorrep(distinct_cmap[colorind], r, g, b)
            end
        end
        r, g, b = RGB(colors[1, scheme])
        rdiff, gdiff, bdiff = RGB(colors[2, scheme]) - [r, g, b]
        for colorind in 1:12
            f = (colorind - 1) / 11.0
            GR.setcolorrep(92 - colorind, r + f*rdiff, g + f*gdiff, b + f*bdiff)
        end
    end

    set_viewport(kind, plt.kvs[:subplot])
    if !plt.kvs[:ax]
        set_window(kind)
        if kind == :polar
            draw_polar_axes()
        elseif kind != :imshow && kind != :isosurface
            draw_axes(kind)
        end
    end

    if haskey(plt.kvs, :colormap)
        GR.setcolormap(plt.kvs[:colormap])
    else
        GR.setcolormap(GR.COLORMAP_VIRIDIS)
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
            if given(z) || given(c)
                if given(c)
                    c = (c - minimum(c)) / (maximum(c) - minimum(c))
                    cind = Int[round(Int, 1000 + _i * 255) for _i in c]
                end
                for i in 1:length(x)
                    given(z) && GR.setmarkersize(z[i] / 100.0)
                    given(c) && GR.setmarkercolorind(cind[i])
                    GR.polymarker([x[i]], [y[i]])
                end
            else
                GR.polymarker(x, y)
            end
        elseif kind == :stem
            GR.setlinecolorind(1)
            GR.polyline([plt.kvs[:window][1]; plt.kvs[:window][2]], [0; 0])
            GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
            GR.uselinespec(spec)
            for i = 1:length(y)
                GR.polyline([x[i]; x[i]], [0; y[i]])
                GR.polymarker([x[i]], [y[i]])
            end
        elseif kind == :hist
            ymin = plt.kvs[:window][3]
            for i = 1:length(y)
                GR.setfillcolorind(989)
                GR.setfillintstyle(GR.INTSTYLE_SOLID)
                GR.fillrect(x[i], x[i+1], ymin, y[i])
                GR.setfillcolorind(1)
                GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
                GR.fillrect(x[i], x[i+1], ymin, y[i])
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
            zmin, zmax = plt.kvs[:zrange]
            GR.setspace(zmin, zmax, 0, 90)
            scale = plt.kvs[:scale]
            GR.setscale(scale)
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
                z = reshape(z, 200, 200)
            end
            GR.surface(x, y, z, GR.OPTION_CELL_ARRAY)
            colorbar()
        elseif kind == :hexbin
            nbins = get(plt.kvs, :nbins, 40)
            cntmax = GR.hexbin(x, y, nbins)
            if cntmax > 0
                plt.kvs[:zrange] = 0, cntmax
                colorbar()
            end
        elseif kind == :heatmap
            xmin, xmax, ymin, ymax = plt.kvs[:window]
            width, height = size(z)
            cmap = colormap()
            data = (float(z) - minimum(z)) / (maximum(z) - minimum(z))
            rgba = [to_rgba(value, cmap) for value = data]
            GR.drawimage(xmin, xmax, ymax, ymin, width, height, rgba)
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
                gr3.clear()
                GR.gr3.surface(x, y, z, GR.OPTION_COLORED_MESH)
            else
                GR.surface(x, y, z, GR.OPTION_COLORED_MESH)
            end
            draw_axes(kind, 2)
            colorbar(0.05)
        elseif kind == :plot3
            GR.polyline3d(x, y, z)
            draw_axes(kind, 2)
        elseif kind == :scatter3
            GR.polymarker3d(x, y, z)
            draw_axes(kind, 2)
        elseif kind == :imshow
            plot_img(z)
        elseif kind == :isosurface
            plot_iso(z)
        elseif kind == :polar
            GR.uselinespec(spec)
            plot_polar(x, y)
        elseif kind == :trisurf
            GR.trisurface(x, y, z)
            draw_axes(kind, 2)
            colorbar(0.05)
        elseif kind == :tricont
            zmin, zmax = plt.kvs[:zrange]
            levels = linspace(zmin, zmax, 20)
            GR.tricontour(x, y, z, levels)
        end
        GR.restorestate()
    end

    if kind in (:line, :scatter, :stem) && haskey(plt.kvs, :labels)
        draw_legend()
    end

    if plt.kvs[:update]
        GR.updatews()
        if GR.isinline()
            restore_context()
            return GR.show()
        end
    end

    flag && restore_context()
    return
end

function plot_args(args; fmt=:xys)
    args = Any[args...]
    parsed_args = Any[]

    while length(args) > 0
        local x, y, z, c
        a = shift!(args)
        if isa(a, AbstractVecOrMat) || isa(a, Function)
            elt = eltype(a)
            if elt <: Complex
                x = real(a)
                y = imag(a)
                z = Void
                c = Void
            elseif elt <: Real || isa(a, Function)
                if fmt == :xys
                    if length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || isa(args[1], Function))
                        x = a
                        y = shift!(args)
                        z = Void
                        c = Void
                    else
                        y = a
                        n = isrowvec(y) ? size(y, 2) : size(y, 1)
                        if haskey(plt.kvs, :xlim)
                            xmin, xmax = plt.kvs[:xlim]
                            x = linspace(xmin, xmax, n)
                        else
                            x = linspace(1, n, n)
                        end
                        z = Void
                        c = Void
                    end
                elseif fmt == :xyac || fmt == :xyzc
                    if length(args) >= 3 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || isa(args[2], Function)) &&
                       (isa(args[3], AbstractVecOrMat) && eltype(args[3]) <: Real || isa(args[3], Function))
                        x = a
                        y = shift!(args)
                        z = shift!(args)
                        c = shift!(args)
                    elseif length(args) >= 2 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || isa(args[2], Function))
                        x = a
                        y = shift!(args)
                        z = shift!(args)
                        c = Void
                    elseif fmt == :xyac && length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || isa(args[1], Function))
                        x = a
                        y = shift!(args)
                        z = Void
                        c = Void
                    elseif fmt == :xyzc && length(args) == 0
                        z = a
                        nx, ny = size(z)
                        if haskey(plt.kvs, :xlim)
                            xmin, xmax = plt.kvs[:xlim]
                            x = linspace(xmin, xmax, nx)
                        else
                            x = linspace(1, nx, nx)
                        end
                        if haskey(plt.kvs, :ylim)
                            ymin, ymax = plt.kvs[:ylim]
                            y = linspace(ymin, ymax, ny)
                        else
                            y = linspace(1, ny, ny)
                        end
                        c = Void
                    end
                end
            else
                error("expected Real or Complex")
            end
        else
            error("expected array or function")
        end
        if isa(y, Function)
            f = y
            y = Float64[f(a) for a in x]
        end
        if isa(z, Function)
            f = z
            z = Float64[f(a,b) for b in y, a in x]
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
        if given(z)
            if fmt == :xyzc && typeof(z) == Function
                z = [z(a,b) for a in x, b in y]
            else
                isvector(z) && (z = vec(z))
            end
        end
        if given(c)
            isvector(c) && (c = vec(c))
        end

        local xyzc
        if !given(z)
            if isa(x, AbstractVector) && isa(y, AbstractVector)
                xyzc = [ (x, y, z, c) ]
            elseif isa(x, AbstractVector)
                xyzc = length(x) == size(y, 1) ?
                       [ (x, view(y,:,j), z, c) for j = 1:size(y, 2) ] :
                       [ (x, view(y,i,:), z, c) for i = 1:size(y, 1) ]
            elseif isa(y, AbstractVector)
                xyzc = size(x, 1) == length(y) ?
                       [ (view(x,:,j), y, z, c) for j = 1:size(x, 2) ] :
                       [ (view(x,i,:), y, z, c) for i = 1:size(x, 1) ]
            else
                @assert size(x) == size(y)
                xyzc = [ (view(x,:,j), view(y,:,j), z, c) for j = 1:size(y, 2) ]
            end
        elseif isa(x, AbstractVector) && isa(y, AbstractVector) &&
               (isa(z, AbstractVector) || typeof(z) == Array{Float64,2} ||
                typeof(z) == Array{Int32,2} || typeof(z) == Array{Any,2})
            xyzc = [ (x, y, z, c) ]
        else
            xyzc = [ (vec(float(x)), vec(float(y)), vec(float(z)), c) ]
        end
        for (x, y, z, c) in xyzc
            push!(pltargs, (x, y, z, c, spec))
        end
    end

    pltargs
end

function plot(args::PlotArg...; kv...)
    create_context(:line, Dict(kv))

    if plt.kvs[:ax]
        plt.args = append!(plt.args, plot_args(args))
    else
        plt.args = plot_args(args)
    end

    plot_data()
end

function oplot(args::PlotArg...; kv...)
    create_context(:line, Dict(kv))

    plt.args = append!(plt.args, plot_args(args))

    plot_data()
end

function scatter(args...; kv...)
    create_context(:scatter, Dict(kv))

    plt.args = plot_args(args, fmt=:xyac)

    plot_data()
end

function stem(args...; kv...)
    create_context(:stem, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

function hist(x, nbins::Integer=0)
    if nbins <= 1
        nbins = round(Int, 3.3 * log10(length(x))) + 1
    end

    xmin, xmax = extrema(x)
    edges = linspace(xmin, xmax, nbins + 1)
    counts = zeros(nbins)
    buckets = Int[max(2, min(searchsortedfirst(edges, xᵢ), length(edges)))-1 for xᵢ in x]
    for b in buckets
        counts[b] += 1
    end
    collect(edges), counts
end

function histogram(x; kv...)
    create_context(:hist, Dict(kv))

    nbins = get(plt.kvs, :nbins, 0)
    x, y = hist(x, nbins)
    plt.args = [(x, y, Void, Void, "")]

    plot_data()
end

function contour(args...; kv...)
    create_context(:contour, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function contourf(args...; kv...)
    create_context(:contourf, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function hexbin(args...; kv...)
    create_context(:hexbin, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

function heatmap(D; kv...)
    create_context(:heatmap, Dict(kv))

    if ndims(D) == 2
        z = D'
        width, height = size(z)
        if !haskey(plt.kvs, :xlim) plt.kvs[:xlim] = (0.5, width + 0.5) end
        if !haskey(plt.kvs, :ylim) plt.kvs[:ylim] = (0.5, height + 0.5) end

        plt.args = [(1:width, 1:height, z, Void, "")]

        plot_data()
    else
        error("expected 2-D array")
    end
end

function wireframe(args...; kv...)
    create_context(:wireframe, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function surface(args...; kv...)
    create_context(:surface, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function plot3(args...; kv...)
    create_context(:plot3, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function scatter3(args...; kv...)
    create_context(:scatter3, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function title(s)
    plt.kvs[:title] = s
end

function xlabel(s)
    plt.kvs[:xlabel] = s
end

function ylabel(s)
    plt.kvs[:ylabel] = s
end

function legend(args::AbstractString...; kv...)
    plt.kvs[:labels] = args
end

function xlim(a)
    plt.kvs[:xlim] = a
end

function ylim(a)
    plt.kvs[:ylim] = a
end

function savefig(filename)
    GR.beginprint(filename)
    plot_data(false)
    GR.endprint()
end

function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T})
    m, n = length(vy), length(vx)
    vx = reshape(vx, 1, n)
    vy = reshape(vy, m, 1)
    (repmat(vx, m, 1), repmat(vy, 1, n))
end

function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T},
                     vz::AbstractVector{T})
    m, n, o = length(vy), length(vx), length(vz)
    vx = reshape(vx, 1, n, 1)
    vy = reshape(vy, m, 1, 1)
    vz = reshape(vz, 1, 1, o)
    om = ones(Int, m)
    on = ones(Int, n)
    oo = ones(Int, o)
    (vx[om, :, oo], vy[:, on, oo], vz[om, on, :])
end

function peaks(n=49)
    x = linspace(-2.5, 2.5, n)
    y = x
    x, y = meshgrid(x, y)
    3*(1-x).^2.*exp.(-(x.^2) - (y+1).^2) - 10*(x/5 - x.^3 - y.^5).*exp.(-x.^2-y.^2) - 1/3*exp.(-(x+1).^2 - y.^2)
end

function imshow(I; kv...)
    create_context(:imshow, Dict(kv))

    plt.args = [(Void, Void, I, Void, "")]

    plot_data()
end

function isosurface(V; kv...)
    create_context(:isosurface, Dict(kv))

    plt.args = [(Void, Void, V, Void, "")]

    plot_data()
end

function cart2sph(x, y, z)
    azimuth = atan2.(y, x)
    elevation = atan2.(z, sqrt.(x.^2 + y.^2))
    r = sqrt.(x.^2 + y.^2 + z.^2)
    azimuth, elevation, r
end

function sph2cart(azimuth, elevation, r)
    x = r .* cos.(elevation) .* cos.(azimuth)
    y = r .* cos.(elevation) .* sin.(azimuth)
    z = r .* sin.(elevation)
    x, y, z
end

function polar(args...; kv...)
    create_context(:polar, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

function trisurf(args...; kv...)
    create_context(:trisurf, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function tricont(args...; kv...)
    create_context(:tricont, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function mainloop()
    server = listen(8001)
    try
        while true
            sock = accept(server)
            while isopen(sock)
                io = IOBuffer()
                write(io, read(sock))
                seekstart(io)

                obj = deserialize(io)
                merge!(plt.kvs, obj["kvs"])
                plt.args = obj["args"]

                plot_data(false)
            end
        end
    end
end

end # module
