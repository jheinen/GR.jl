module jlgr

import GR

using Serialization
using Sockets

const None = Union{}

function search(s::AbstractString, c::Char)
    result = findfirst(isequal(c), s)
    result != nothing ? result : 0
end

signif(x, digits; base = 10) = round(x, sigdigits = digits, base = base)

macro _tuple(t)
    :( Tuple{$t} )
end

const PlotArg = Union{AbstractString, AbstractVector, AbstractMatrix, Function}

const gr3 = GR.gr3

const plot_kind = [:line, :step, :scatter, :stem, :hist, :contour, :contourf, :hexbin, :heatmap, :nonuniformheatmap, :wireframe, :surface, :plot3, :scatter3, :imshow, :isosurface, :polar, :polarhist, :polarheatmap, :nonuniformpolarheatmap, :trisurf, :tricont, :shade, :volume]

const arg_fmt = [:xys, :xyac, :xyzc]

const kw_args = [:accelerate, :algorithm, :alpha, :backgroundcolor, :barwidth, :baseline, :clabels, :color, :colormap, :figsize, :font, :isovalue, :labels, :levels, :location, :nbins, :rotation, :size, :tilt, :title, :where, :xflip, :xform, :xlabel, :xlim, :xlog, :yflip, :ylabel, :ylim, :ylog, :zflip, :zlabel, :zlim, :zlog, :clim, :subplot]

const colors = [
    [0xffffff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0x00ffff, 0xffff00, 0xff00ff] [0x282c34, 0xd7dae0, 0xcb4e42, 0x99c27c, 0x85a9fc, 0x5ab6c1, 0xd09a6a, 0xc57bdb] [0xfdf6e3, 0x657b83, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682] [0x002b36, 0x839496, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682]
    ]

const fonts = Dict(
    "Times_Roman" => 101, "Times_Italic" => 102, "Times_Bold" => 103, "Times_BoldItalic" => 104,
    "Helvetica_Regular" => 105, "Helvetica_Oblique" => 106, "Helvetica_Bold" => 107, "Helvetica_BoldOblique" => 108,
    "Courier_Regular" => 109, "Courier_Oblique" => 110, "Courier_Bold" => 111, "Courier_BoldOblique" => 112,
    "Symbol" => 113,
    "Bookman_Light" => 114, "Bookman_LightItalic" => 115, "Bookman_Demi" => 116, "Bookman_DemiItalic" => 117,
    "NewCenturySchlbk_Roman" => 118, "NewCenturySchlbk_Italic" => 119, "NewCenturySchlbk_Bold" => 120, "NewCenturySchlbk_BoldItalic" => 121,
    "AvantGarde_Book" => 122, "AvantGarde_BookOblique" => 123, "AvantGarde_Demi" => 124, "AvantGarde_DemiOblique" => 125,
    "Palatino_Roman" => 126, "Palatino_Italic" => 127, "Palatino_Bold" => 128, "Palatino_BoldItalic" => 129,
    "ZapfChancery_MediumItalic" => 130,
    "ZapfDingbats" => 131,
    "CMUSerif-Math" => 232,
    "DejaVuSans" => 233,
    "PingFangSC" => 234)

const distinct_cmap = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

function linspace(start, stop, length)
  range(start, stop=stop, length=length)
end

repmat(A::AbstractArray, m::Int, n::Int) = repeat(A::AbstractArray, m::Int, n::Int)

function _min(a)
  minimum(filter(!isnan, a))
end

function _max(a)
  maximum(filter(!isnan, a))
end

mutable struct PlotObject
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
    kvs[:panzoom] = None
    PlotObject(obj, args, kvs)
end

function gcf()
    plt.kvs
end

plt = Figure()
ctx = Dict()
scheme = 0
background = 0xffffff
handle = nothing

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
    vp = copy(float(subplot))
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
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf, :volume)
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

    if kind in (:contour, :contourf, :hexbin, :heatmap, :nonuniformheatmap, :polarheatmap, :nonuniformpolarheatmap, :surface, :trisurf, :volume)
        viewport[2] -= 0.1
    end
    if kind in (:line, :step, :scatter, :stem) && haskey(plt.kvs, :labels)
        location = get(plt.kvs, :location, 1)
        if location in (11, 12, 13)
            w, h = legend_size()
            viewport[2] -= w + 0.1
        end
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

    if kind in (:polar, :polarhist, :polarheatmap, :nonuniformpolarheatmap)
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
    a != Nothing && a != "Nothing"
end

function Extrema64(a)
    amin =  typemax(Float64)
    amax = -typemax(Float64)
    for el in a
        if !isnan(el)
            if isnan(amin) || el < amin
                amin = el
            end
            if isnan(amax) || el > amax
                amax = el
            end
        end
    end
    amin, amax
end

function minmax()
    xmin = ymin = zmin = cmin =  typemax(Float64)
    xmax = ymax = zmax = cmax = -typemax(Float64)
    scale = plt.kvs[:scale]
    for (x, y, z, c, spec) in plt.args
        if given(x)
            if scale & GR.OPTION_X_LOG != 0
                x = map(v -> v>0 ? v : NaN, x)
            end
            x0, x1 = Extrema64(x)
            xmin = min(x0, xmin)
            xmax = max(x1, xmax)
        else
            xmin, xmax = 0, 1
        end
        if given(y)
            if scale & GR.OPTION_Y_LOG != 0
                y = map(v -> v>0 ? v : NaN, y)
            end
            y0, y1 = Extrema64(y)
            ymin = min(y0, ymin)
            ymax = max(y1, ymax)
        else
            ymin, ymax = 0, 1
        end
        if given(z)
            if scale & GR.OPTION_Z_LOG != 0
                z = map(v -> v>0 ? v : NaN, z)
            end
            z0, z1 = Extrema64(z)
            zmin = min(z0, zmin)
            zmax = max(z1, zmax)
        end
        if given(c)
            c0, c1 = Extrema64(c)
            cmin = min(c0, cmin)
            cmax = max(c1, cmax)
        elseif given(z)
            c0, c1 = Extrema64(z)
            cmin = min(c0, cmin)
            cmax = max(c1, cmax)
        end
    end
    xmin, xmax = fix_minmax(xmin, xmax)
    ymin, ymax = fix_minmax(ymin, ymax)
    zmin, zmax = fix_minmax(zmin, zmax)
    if haskey(plt.kvs, :xlim)
        x0, x1 = plt.kvs[:xlim]
        if x0 === Nothing x0 = xmin end
        if x1 === Nothing x1 = xmax end
        plt.kvs[:xrange] = (x0, x1)
    else
        plt.kvs[:xrange] = xmin, xmax
    end
    if haskey(plt.kvs, :ylim)
        y0, y1 = plt.kvs[:ylim]
        if y0 === Nothing y0 = ymin end
        if y1 === Nothing y1 = ymax end
        plt.kvs[:yrange] = (y0, y1)
    else
        plt.kvs[:yrange] = ymin, ymax
    end
    if haskey(plt.kvs, :zlim)
        z0, z1 = plt.kvs[:zlim]
        if z0 === Nothing z0 = zmin end
        if z1 === Nothing z1 = zmax end
        plt.kvs[:zrange] = (z0, z1)
    else
        plt.kvs[:zrange] = zmin, zmax
    end
    if haskey(plt.kvs, :clim)
        c0, c1 = plt.kvs[:clim]
        if c0 === Nothing c0 = cmin end
        if c1 === Nothing c1 = cmax end
        plt.kvs[:crange] = (c0, c1)
    else
        plt.kvs[:crange] = cmin, cmax
    end
end

function to_wc(wn)
    xmin, ymin = GR.ndctowc(wn[1], wn[3])
    xmax, ymax = GR.ndctowc(wn[2], wn[4])
    xmin, xmax, ymin, ymax
end

function set_window(kind)
    scale = 0
    if !(kind in (:polar, :polarhist, :polarheatmap, :nonuniformpolarheatmap))
        get(plt.kvs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
        get(plt.kvs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
        get(plt.kvs, :zlog, false) && (scale |= GR.OPTION_Z_LOG)
        get(plt.kvs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
        get(plt.kvs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)
        get(plt.kvs, :zflip, false) && (scale |= GR.OPTION_FLIP_Z)
    end
    plt.kvs[:scale] = scale

    if plt.kvs[:panzoom] != None
        xmin, xmax, ymin, ymax = GR.panzoom(plt.kvs[:panzoom]...)
        plt.kvs[:xrange] = (xmin, xmax)
        plt.kvs[:yrange] = (ymin, ymax)
    else
        minmax()
    end

    if kind in (:wireframe, :surface, :plot3, :scatter3, :polar, :polarhist, :polarheatmap, :nonuniformpolarheatmap, :trisurf, :volume)
        major_count = 2
    else
        major_count = 5
    end

    xmin, xmax = plt.kvs[:xrange]
    if kind in (:heatmap, :polarheatmap) && !haskey(plt.kvs, :xlim)
        xmin -= 0.5
        xmax += 0.5
    end
    if scale & GR.OPTION_X_LOG == 0
        if !haskey(plt.kvs, :xlim) && plt.kvs[:panzoom] == None && !(kind in (:heatmap, :polarheatmap, :nonuniformpolarheatmap))
            xmin, xmax = GR.adjustlimits(xmin, xmax)
        end
        if haskey(plt.kvs, :xticks)
            xtick, majorx = plt.kvs[:xticks]
        else
            majorx = major_count
            xtick = GR.tick(xmin, xmax) / majorx
        end
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
    if kind in (:heatmap, :polarheatmap) && !haskey(plt.kvs, :ylim)
        ymin -= 0.5
        ymax += 0.5
    end
    if kind == :hist && !haskey(plt.kvs, :ylim)
        ymin = scale & GR.OPTION_Y_LOG == 0 ? 0 : 1
    end
    if scale & GR.OPTION_Y_LOG == 0
        if !haskey(plt.kvs, :ylim) && plt.kvs[:panzoom] == None && !(kind in (:heatmap, :polarheatmap, :nonuniformpolarheatmap))
            ymin, ymax = GR.adjustlimits(ymin, ymax)
        end
        if haskey(plt.kvs, :yticks)
            ytick, majory = plt.kvs[:yticks]
        else
            majory = major_count
            ytick = GR.tick(ymin, ymax) / majory
        end
    else
        ytick = majory = 1
    end
    if scale & GR.OPTION_FLIP_Y == 0
        yorg = (ymin, ymax)
    else
        yorg = (ymax, ymin)
    end
    plt.kvs[:yaxis] = ytick, yorg, majory

    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf, :volume)
        zmin, zmax = plt.kvs[:zrange]
        if scale & GR.OPTION_Z_LOG == 0
            if !haskey(plt.kvs, :zlim)
                zmin, zmax = GR.adjustlimits(zmin, zmax)
            end
            if haskey(plt.kvs, :zticks)
                ztick, majorz = plt.kvs[:zticks]
            else
                majorz = major_count
                ztick = GR.tick(zmin, zmax) / majorz
            end
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
    if !(kind in (:polar, :polarhist, :polarheatmap, :nonuniformpolarheatmap))
        GR.setwindow(xmin, xmax, ymin, ymax)
    else
        GR.setwindow(-1, 1, -1, 1)
    end
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf, :volume)
        rotation = get(plt.kvs, :rotation, 40)
        tilt = get(plt.kvs, :tilt, 70)
        GR.setspace(zmin, zmax, rotation, tilt)
    end

    plt.kvs[:scale] = scale
    GR.setscale(scale)
end

function ticklabel_fun(f::Function)
    return (x, y, svalue, value) -> GR.textext(x, y, string(f(value)))
end

function ticklabel_fun(labels::AbstractVecOrMat{T}) where T <: AbstractString
    (x, y, svalue, value) -> begin
        pos = findfirst(t->(value≈t), collect(1:length(labels)))
        lab = (pos == nothing) ? "" : labels[pos]
        GR.textext(x, y, lab)
    end
end

function draw_axes(kind, pass=1)
    viewport = plt.kvs[:viewport]
    vp = plt.kvs[:vp]
    ratio = plt.kvs[:ratio]
    xtick, xorg, majorx = plt.kvs[:xaxis]
    ytick, yorg, majory = plt.kvs[:yaxis]
    drawgrid = get(plt.kvs, :grid, true)
    # enforce scientific notation for logarithmic axes labels
    if plt.kvs[:scale] & GR.OPTION_X_LOG != 0
        xtick = 10
    end
    if plt.kvs[:scale] & GR.OPTION_Y_LOG != 0
        ytick = 10
    end
    GR.setlinecolorind(1)
    diag = sqrt((viewport[2] - viewport[1])^2 + (viewport[4] - viewport[3])^2)
    GR.setlinewidth(1)
    charheight = max(0.018 * diag, 0.012)
    GR.setcharheight(charheight)
    ticksize = 0.0075 * diag
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf, :volume)
        ztick, zorg, majorz = plt.kvs[:zaxis]
        if pass == 1 && drawgrid
            GR.grid3d(xtick, 0, ztick, xorg[1], yorg[2], zorg[1], 2, 0, 2)
            GR.grid3d(0, ytick, 0, xorg[1], yorg[2], zorg[1], 0, 2, 0)
        else
            GR.axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], majorx, 0, majorz, -ticksize)
            GR.axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, majory, 0, ticksize)
        end
    else
        if kind in (:heatmap, :nonuniformheatmap, :shade)
            ticksize = -ticksize
        else
            drawgrid && GR.grid(xtick, ytick, 0, 0, majorx, majory)
        end
        if haskey(plt.kvs, :xticklabels) || haskey(plt.kvs, :yticklabels)
            fx = get(plt.kvs, :xticklabels, identity) |> ticklabel_fun
            fy = get(plt.kvs, :yticklabels, identity) |> ticklabel_fun
            GR.axeslbl(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize, fx, fy)
        else
            GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
        end
        GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
    end

    if haskey(plt.kvs, :title)
        GR.savestate()
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        text(0.5 * (viewport[1] + viewport[2]), vp[4], plt.kvs[:title])
        GR.restorestate()
    end
    if kind in (:wireframe, :surface, :plot3, :scatter3, :trisurf, :volume)
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
    n = trunc(Int, (rmax - rmin) / tick)
    for i in 0:n
        r = rmin + i * tick / (rmax - rmin)
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
        sinf = sin(alpha * π / 180)
        cosf = cos(alpha * π / 180)
        GR.polyline([cosf, 0], [sinf, 0])
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)
        x, y = GR.wctondc(1.1 * cosf, 1.1 * sinf)
        GR.textext(x, y, string(alpha, "^o"))
    end
    GR.restorestate()
end

function inqtext(x, y, s)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.inqmathtex(x, y, s[2:end-1])
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

function legend_size()
    scale = Int(GR.inqscale())
    GR.selntran(0)
    GR.setscale(0)
    w = 0
    h = 0
    for label in plt.kvs[:labels]
        tbx, tby = inqtext(0, 0, label)
        w  = max(w, tbx[3] - tbx[1])
        h += max(tby[3] - tby[1], 0.03)
    end
    GR.setscale(scale)
    GR.selntran(1)
    w, h
end

hasline(mask) = ( mask == 0x00 || (mask & 0x01 != 0) )
hasmarker(mask) = ( mask & 0x02 != 0)

function draw_legend()
    w, h = legend_size()
    viewport = plt.kvs[:viewport]
    location = get(plt.kvs, :location, 1)
    num_labels = length(plt.kvs[:labels])
    GR.savestate()
    GR.selntran(0)
    GR.setscale(0)
    if location in (11, 12, 13)
        px = viewport[2] + 0.11
    elseif location in (8, 9, 10)
        px = 0.5 * (viewport[1] + viewport[2] - w + 0.05)
    elseif location in (2, 3, 6)
        px = viewport[1] + 0.11
    else
        px = viewport[2] - 0.05 - w
    end
    if location in (5, 6, 7, 10, 12)
        py = 0.5 * (viewport[3] + viewport[4] + h - 0.03)
    elseif location == 13
        py = viewport[3] + h
    elseif location in (3, 4, 8)
        py = viewport[3] + h + 0.03
    elseif location == 11
        py = viewport[4] - 0.03
    else
        py = viewport[4] - 0.06
    end
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(0)
    GR.fillrect(px - 0.08, px + w + 0.02, py + 0.03, py - h)
    GR.setlinetype(GR.LINETYPE_SOLID)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    GR.drawrect(px - 0.08, px + w + 0.02, py + 0.03, py - h)
    i = 1
    GR.uselinespec(" ")
    for (x, y, z, c, spec) in plt.args
        if i <= num_labels
            label = plt.kvs[:labels][i]
            tbx, tby = inqtext(0, 0, label)
            dy = max((tby[3] - tby[1]) - 0.03, 0)
            py -= 0.5 * dy
        end
        GR.savestate()
        mask = GR.uselinespec(spec)
        hasline(mask) && GR.polyline([px - 0.07, px - 0.01], [py, py])
        hasmarker(mask) && GR.polymarker([px - 0.06, px - 0.02], [py, py])
        GR.restorestate()
        GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
        if i <= num_labels
            text(px, py, label)
            py -= 0.5 * dy
            i += 1
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
    mask = (GR.OPTION_Z_LOG | GR.OPTION_FLIP_Y | GR.OPTION_FLIP_Z)
    if get(plt.kvs, :zflip, false)
        options = (GR.inqscale() | GR.OPTION_FLIP_Y)
        GR.setscale(options & mask)
    elseif get(plt.kvs, :yflip, false)
        options = GR.inqscale() & ~GR.OPTION_FLIP_Y
        GR.setscale(options & mask)
    else
        options = GR.inqscale()
        GR.setscale(options & mask)
    end
    h = 0.5 * (zmax - zmin) / (colors - 1)
    GR.setwindow(0, 1, zmin, zmax)
    GR.setviewport(viewport[2] + 0.02 + off, viewport[2] + 0.05 + off,
                   viewport[3], viewport[4])
    l = zeros(Int32, 1, colors)
    l[1,:] = Int[round(Int, _i) for _i in linspace(1000, 1255, colors)]
    GR.cellarray(0, 1, zmax + h, zmin - h, 1, colors, l)
    GR.setlinecolorind(1)
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
    round(UInt32, a * 255) << 24 + round(UInt32, b * 255) << 16 +
    round(UInt32, g * 255) << 8  + round(UInt32, r * 255)
end

function create_context(kind::Symbol, dict=plt.kvs)
    plt.kvs[:kind] = kind
    create_context(dict)
end

function create_context(dict::AbstractDict)
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

"""
Create a new figure with the given settings.

Settings like the current colormap, title or axis limits as stored in the
current figure. This function creates a new figure, restores the default
settings and applies any settings passed to the function as keyword
arguments.

**Usage examples:**

.. code-block:: julia

    julia> # Restore all default settings
    julia> figure()
    julia> # Restore all default settings and set the title
    julia> figure(title="Example Figure")
"""
function figure(; kv...)
    global plt
    plt = Figure()
    merge!(plt.kvs, Dict(kv))
    plt
end

"""
Set the hold flag for combining multiple plots.

The hold flag prevents drawing of axes and clearing of previous plots, so
that the next plot will be drawn on top of the previous one.

:param flag: the value of the hold flag

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(0, 1, 100)
    julia> # Draw the first plot
    julia> plot(x, x.^2)
    julia> # Set the hold flag
    julia> hold(true)
    julia> # Draw additional plots
    julia> plot(x, x.^4)
    julia> plot(x, x.^8)
    julia> # Reset the hold flag
    julia> hold(false)
"""
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

"""
Set current subplot index.

By default, the current plot will cover the whole window. To display more
than one plot, the window can be split into a number of rows and columns,
with the current plot covering one or more cells in the resulting grid.

Subplot indices are one-based and start at the upper left corner, with a
new row starting after every **num_columns** subplots.

:param num_rows: the number of subplot rows
:param num_columns: the number of subplot columns
:param subplot_indices:
	- the subplot index to be used by the current plot
	- a pair of subplot indices, setting which subplots should be covered
	  by the current plot

**Usage examples:**

.. code-block:: julia

    julia> # Set the current plot to the second subplot in a 2x3 grid
    julia> subplot(2, 3, 2)
    julia> # Set the current plot to cover the first two rows of a 4x2 grid
    julia> subplot(4, 2, (1, 4))
    julia> # Use the full window for the current plot
    julia> subplot(1, 1, 1)
"""
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

"""
Set the flag to draw a grid in the plot axes.

:param flag: the value of the grid flag (`true` by default)

**Usage examples:**

.. code-block:: julia

    julia> # Hid the grid on the next plot
    julia> grid(false)
    julia> # Restore the grid
    julia> grid(true)
"""
drawgrid(flag) = (plt.kvs[:grid] = flag)

const doc_ticks = """
Set the intervals of the ticks for the X, Y or Z axis.

Use the function `xticks`, `yticks` or `zticks` for the corresponding axis.

:param minor: the interval between minor ticks.
:param major: (optional) the number of minor ticks between major ticks.

**Usage examples:**

.. code-block:: julia

    julia> # Minor ticks every 0.2 units in the X axis
    julia> xticks(0.2)
    julia> # Major ticks every 1 unit (5 minor ticks) in the Y axis
    julia> yticks(0.2, 5)
"""

@doc doc_ticks xticks(minor, major::Int=1) = (plt.kvs[:xticks] = (minor, major))
@doc doc_ticks yticks(minor, major::Int=1) = (plt.kvs[:yticks] = (minor, major))
@doc doc_ticks zticks(minor, major::Int=1) = (plt.kvs[:zticks] = (minor, major))

const doc_ticklabels = """
Customize the string of the X and Y axes tick labels.

The labels of the tick axis can be defined through a function
with one argument (the numeric value of the tick position) and
returns a string, or through an array of strings that are located
sequentially at X = 1, 2, etc.

:param s: function or array of strings that define the tick labels.

**Usage examples:**

.. code-block:: julia

    julia> # Label the range (0-1) of the Y-axis as percent values
    julia> yticklabels(p -> Base.Printf.@sprintf("%0.0f%%", 100p))
    julia> # Label the X-axis with a sequence of strings
    julia> xticklabels(["first", "second", "third"])
"""
@doc doc_ticklabels xticklabels(s) = (plt.kvs[:xticklabels] = s)
@doc doc_ticklabels yticklabels(s) = (plt.kvs[:yticklabels] = s)

# Normalize a color c with the range [cmin, cmax]
#   0 <= normalize_color(c, cmin, cmax) <= 1
function normalize_color(c, cmin, cmax)
    c = clamp(float(c), cmin, cmax) - cmin
    if cmin != cmax
        c /= cmax - cmin
    end
    c
end

function plot_img(I)
    viewport = plt.kvs[:vp][:]
    if haskey(plt.kvs, :title)
        viewport[4] -= 0.05
    end
    vp = plt.kvs[:vp]

    if isa(I, AbstractString)
        width, height, data = GR.readimage(I)
    else
        I = I'
        width, height = size(I)
        cmin, cmax = plt.kvs[:crange]
        data = map(x -> normalize_color(x, cmin, cmax), I)
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
    GR.setscale(0)
    if get(plt.kvs, :xflip, false)
        tmp = xmax; xmax = xmin; xmin = tmp;
    end
    if get(plt.kvs, :yflip, false)
        tmp = ymax; ymax = ymin; ymin = tmp;
    end
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
    values = round.(UInt16, (V .- _min(V)) ./ (_max(V) .- _min(V)) .* (2^16-1))
    nx, ny, nz = size(V)
    isovalue = (get(plt.kvs, :isovalue, 0.5) - _min(V)) / (_max(V) - _min(V))
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
    ρ = ρ ./ rmax
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

to_double(a) = Float64[float(el) for el in a]
to_int(a) = Int32[round(Int32, el) for el in a]

function send_data(handle, name, data)
    GR.sendmetaref(handle, name, 'D', to_double(data))
    dims = size(data)
    if length(dims) > 1
        GR.sendmetaref(handle, string(name, "_dims"), 'I', to_int(dims))
    end
end

function send_meta(target)
    global handle
    if handle === nothing
        handle = GR.openmeta(target)
    end
    if handle != C_NULL
        for (k, v) in plt.kvs
            if k in [:backgroundcolor, :color, :colormap, :location, :nbins,
                     :rotation, :tilt, :xform]
                GR.sendmetaref(handle, string(k), 'i', Int32(v))
            elseif k in [:alpha, :isovalue]
                GR.sendmetaref(handle, string(k), 'd', Float64(v))
            elseif k in [:xlim, :ylim, :zlim, :clim, :size]
                GR.sendmetaref(handle, string(k), 'D', to_double(v))
            elseif k in [:title, :xlabel, :ylabel, :zlabel]
                GR.sendmetaref(handle, string(k), 's', string(v))
            elseif k in [:labels]
                GR.sendmetaref(handle, string(k), 'S', v, length(v))
            elseif k in [:xflip, :yflip, :zflip, :xlog, :ylog, :zlog]
                GR.sendmetaref(handle, string(k), 'i', v ? 1 : 0)
            end
        end
        num_series = length(plt.args)
        GR.sendmetaref(handle, "series", 'O', "[", num_series)
        for (i, (x, y, z, c, spec)) in enumerate(plt.args)
            given(x) && send_data(handle, "x", to_double(x))
            given(y) && send_data(handle, "y", to_double(y))
            given(z) && send_data(handle, "z", to_double(z))
            given(c) && send_data(handle, "c", to_double(c))
            given(spec) && GR.sendmetaref(handle, "spec", 's', spec)
            GR.sendmetaref(handle, "", 'O', i < num_series ? "," : "]", 1)
        end
        if plt.kvs[:kind] == :hist
            GR.sendmetaref(handle, "kind", 's', "barplot");
        else
            GR.sendmetaref(handle, "kind", 's', string(plt.kvs[:kind]));
        end
        GR.sendmetaref(handle, "", '\0', "", 0);
        #GR.closemeta(handle)
    end
end

function send_serialized(target)
    handle = connect(target, 8001)
    io = IOBuffer()
    serialize(io, Dict("kvs" => plt.kvs, "args" => plt.args))
    write(handle, io.data)
    close(handle)
end

function contains_NaN(a)
    for el in a
        if el === NaN
            return true
        end
    end
    false
end

function plot_data(flag=true)
    global scheme, background

    if plt.args == @_tuple(Any)
        return
    end

    GR.init()

    target = GR.displayname()
    if flag && target != None
        if target == "js" || target == "meta" || target == "pluto"
            send_meta(0)
        else
            send_serialized(target)
        end
        if target == "pluto"
          return GR.js.get_pluto_html()
        end
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

    if haskey(plt.kvs, :font)
        name = plt.kvs[:font]
        if haskey(fonts, name)
            font = fonts[name]
            GR.settextfontprec(font, font > 200 ? 3 : 0)
        else
            println("Unknown font name: $name")
        end
    else
        GR.settextfontprec(232, 3) # CM Serif Roman
    end

    set_viewport(kind, plt.kvs[:subplot])
    if !plt.kvs[:ax]
        set_window(kind)
        if kind in (:polar, :polarhist)
            draw_polar_axes()
        elseif !(kind in (:imshow, :isosurface, :polarheatmap, :nonuniformpolarheatmap))
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
            hasline(mask) && GR.polyline(x, y)
            hasmarker(mask) && GR.polymarker(x, y)
        elseif kind == :step
            mask = GR.uselinespec(spec)
            if hasline(mask)
                where = get(plt.kvs, :where, "mid")
                if where == "pre"
                    n = length(x)
                    xs = zeros(2 * n - 1)
                    ys = zeros(2 * n - 1)
                    xs[1] = x[1]
                    ys[1] = y[1]
                    for i in 1:n-1
                        xs[2*i]   = x[i]
                        xs[2*i+1] = x[i+1]
                        ys[2*i]   = y[i+1]
                        ys[2*i+1] = y[i+1]
                    end
                elseif where == "post"
                    n = length(x)
                    xs = zeros(2 * n - 1)
                    ys = zeros(2 * n - 1)
                    xs[1] = x[1]
                    ys[1] = y[1]
                    for i in 1:n-1
                        xs[2*i]   = x[i+1]
                        xs[2*i+1] = x[i+1]
                        ys[2*i]   = y[i]
                        ys[2*i+1] = y[i+1]
                    end
                else
                    n = length(x)
                    xs = zeros(2 * n)
                    ys = zeros(2 * n)
                    xs[1] = x[1]
                    for i in 1:n-1
                        xs[2*i]   = 0.5 * (x[i] + x[i+1])
                        xs[2*i+1] = 0.5 * (x[i] + x[i+1])
                        ys[2*i-1] = y[i]
                        ys[2*i]   = y[i]
                    end
                    xs[2*n]   = x[n]
                    ys[2*n-1] = y[n]
                    ys[2*n]   = y[n]
                end
                GR.polyline(xs, ys)
            end
            hasmarker(mask) && GR.polymarker(x, y)
        elseif kind == :scatter
            GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
            if given(z) || given(c)
                if given(c)
                    cmin, cmax = plt.kvs[:crange]
                    c = map(x -> normalize_color(x, cmin, cmax), c)
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
        elseif kind == :polarhist
            ymax = plt.kvs[:window][4]
            ρ = y ./ ymax
            θ = x * 180/π
            for i = 2:length(ρ)
                GR.setfillcolorind(989)
                GR.setfillintstyle(GR.INTSTYLE_SOLID)
                GR.fillarc(-ρ[i], ρ[i], -ρ[i], ρ[i], θ[i-1], θ[i])
                GR.setfillcolorind(1)
                GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
                GR.fillarc(-ρ[i], ρ[i], -ρ[i], ρ[i], θ[i-1], θ[i])
            end
        elseif kind in (:polarheatmap, :nonuniformpolarheatmap)
            w, h = size(z)
            cmap = colormap()
            cmin, cmax = plt.kvs[:zrange]
            data = map(x -> normalize_color(x, cmin, cmax), z)
            if get(plt.kvs, :xflip, false)
                data = reverse(data, dims=1)
            end
            if get(plt.kvs, :yflip, false)
                data = reverse(data, dims=2)
            end
            colors = Int[round(Int, 1000 + _i * 255) for _i in data]
            if kind == :polarheatmap
                GR.polarcellarray(0, 0, 0, 360, 0, 1, w, h, colors)
            else
                ymin, ymax = plt.kvs[:window][3:4]
                ρ = ymin .+ y ./ (ymax - ymin)
                θ = x * 180/π
                GR.nonuniformpolarcellarray(θ, ρ, w, h, colors)
            end
            draw_polar_axes()
            plt.kvs[:zrange] = cmin, cmax
            colorbar()
        elseif kind == :contour
            zmin, zmax = plt.kvs[:zrange]
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
                zmin, zmax = get(plt.kvs, :zlim, (_min(z), _max(z)))
            end
            GR.setspace(zmin, zmax, 0, 90)
            levels = get(plt.kvs, :levels, 0)
            clabels = get(plt.kvs, :clabels, false)
            if typeof(levels) <: Int
                hmin, hmax = GR.adjustrange(zmin, zmax)
                h = linspace(hmin, hmax, levels == 0 ? 21 : levels + 1)
            else
                h = float(levels)
            end
            GR.contour(x, y, h, z, clabels ? 1 : 1000)
            colorbar(0, length(h))
        elseif kind == :contourf
            zmin, zmax = plt.kvs[:zrange]
            if length(x) == length(y) == length(z)
                x, y, z = GR.gridit(x, y, z, 200, 200)
                zmin, zmax = get(plt.kvs, :zlim, (_min(z), _max(z)))
            end
            GR.setspace(zmin, zmax, 0, 90)
            levels = get(plt.kvs, :levels, 0)
            clabels = get(plt.kvs, :clabels, false)
            if typeof(levels) <: Int
                hmin, hmax = GR.adjustrange(zmin, zmax)
                h = linspace(hmin, hmax, levels == 0 ? 21 : levels + 1)
            else
                h = float(levels)
            end
            GR.contourf(x, y, h, z, clabels ? 1 : 0)
            colorbar(0, length(h))
        elseif kind == :hexbin
            nbins = get(plt.kvs, :nbins, 40)
            cntmax = GR.hexbin(x, y, nbins)
            if cntmax > 0
                plt.kvs[:zrange] = 0, cntmax
                colorbar()
            end
        elseif kind in (:heatmap, :nonuniformheatmap)
            w, h = size(z)
            cmap = colormap()
            cmin, cmax = plt.kvs[:crange]
            levels = get(plt.kvs, :levels, 256)
            data = map(x -> normalize_color(x, cmin, cmax), z)
            if kind == :heatmap
                rgba = [to_rgba(value, cmap) for value = data]
                GR.drawimage(0.5, w + 0.5, h + 0.5, 0.5, w, h, rgba)
            else
                colors = Int[round(Int, isnan(_i) ? 1256 : 1000 + _i * 255) for _i in data]
                GR.nonuniformcellarray(x, y, w, h, colors)
            end
            colorbar(0, levels)
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
        elseif kind == :volume
            algorithm = get(plt.kvs, :algorithm, 0)
            gr3.clear()
            dmin, dmax = GR.gr3.volume(z, algorithm)
            draw_axes(kind, 2)
            plt.kvs[:zrange] = dmin, dmax
            colorbar(0.05)
        elseif kind == :plot3
            GR.polyline3d(x, y, z)
            draw_axes(kind, 2)
        elseif kind == :scatter3
            GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
            if given(c)
                cmin, cmax = plt.kvs[:crange]
                c = map(x -> normalize_color(x, cmin, cmax), c)
                cind = Int[round(Int, 1000 + _i * 255) for _i in c]
                for i in 1:length(x)
                    GR.setmarkercolorind(cind[i])
                    GR.polymarker3d([x[i]], [y[i]], [z[i]])
                end
            else
                GR.polymarker3d(x, y, z)
            end
            draw_axes(kind, 2)
        elseif kind == :imshow
            plot_img(c)
        elseif kind == :isosurface
            plot_iso(c)
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
        elseif kind == :shade
            xform = get(plt.kvs, :xform, 5)
            if contains_NaN(x)
                GR.shadelines(x, y, xform=xform)
            else
                GR.shadepoints(x, y, xform=xform)
            end
        elseif kind == :bar
            for i = 1:2:length(x)
                GR.setfillcolorind(989)
                GR.setfillintstyle(GR.INTSTYLE_SOLID)
                GR.fillrect(x[i], x[i+1], y[i], y[i+1])
                GR.setfillcolorind(1)
                GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
                GR.fillrect(x[i], x[i+1], y[i], y[i+1])
            end
        end
        GR.restorestate()
    end

    if kind in (:line, :step, :scatter, :stem) && haskey(plt.kvs, :labels)
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
        a = popfirst!(args)
        if isa(a, AbstractVecOrMat) || isa(a, Function)
            elt = eltype(a)
            if elt <: Complex
                x = real(a)
                y = imag(a)
                z = Nothing
                c = Nothing
            elseif elt <: Real || isa(a, Function)
                if fmt == :xys
                    if length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || isa(args[1], Function))
                        x = a
                        y = popfirst!(args)
                        z = Nothing
                        c = Nothing
                    else
                        y = a
                        n = isrowvec(y) ? size(y, 2) : size(y, 1)
                        if haskey(plt.kvs, :xlim)
                            xmin, xmax = plt.kvs[:xlim]
                            x = linspace(xmin, xmax, n)
                        else
                            x = linspace(1, n, n)
                        end
                        z = Nothing
                        c = Nothing
                    end
                elseif fmt == :xyac || fmt == :xyzc
                    if length(args) >= 3 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || isa(args[2], Function)) &&
                       (isa(args[3], AbstractVecOrMat) && eltype(args[3]) <: Real || isa(args[3], Function))
                        x = a
                        y = popfirst!(args)
                        z = popfirst!(args)
                        if !isa(z, Function)
                            z = z'
                        end
                        c = popfirst!(args)
                    elseif length(args) >= 2 &&
                        isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real &&
                       (isa(args[2], AbstractVecOrMat) && eltype(args[2]) <: Real || isa(args[2], Function))
                        x = a
                        y = popfirst!(args)
                        z = popfirst!(args)
                        if !isa(z, Function)
                            z = z'
                        end
                        c = Nothing
                    elseif fmt == :xyac && length(args) >= 1 &&
                       (isa(args[1], AbstractVecOrMat) && eltype(args[1]) <: Real || isa(args[1], Function))
                        x = a
                        y = popfirst!(args)
                        z = Nothing
                        c = Nothing
                    elseif fmt == :xyzc && length(args) == 0
                        z = a'
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
                        c = Nothing
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
            z = Float64[f(a,b) for a in x, b in y]
        end
        spec = ""
        if fmt == :xys && length(args) > 0 && isa(args[1], AbstractString)
            spec = popfirst!(args)
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

        if isa(y, Function)
            y = [y(a) for a in x]
        else
            isvector(y) && (y = vec(y))
        end
        if given(z)
            if fmt == :xyzc && isa(z, Function)
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

"""
Draw one or more line plots.

This function can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia-repl

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 2 .* x .+ 4
    julia> # Plot x and y
    julia> plot(x, y)
    julia> # Plot x and a callable
    julia> plot(x, t -> t^3 + t^2 + t)
    julia> # Plot y, using its indices for the x values
    julia> plot(y)

"""
function plot(args::PlotArg...; kv...)
    create_context(:line, Dict(kv))

    if plt.kvs[:ax]
        plt.args = append!(plt.args, plot_args(args))
    else
        plt.args = plot_args(args)
    end

    plot_data()
end

"""
Draw one or more line plots over another plot.

This function can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 2 .* x .+ 4
    julia> # Draw the first plot
    julia> plot(x, y)
    julia> # Plot graph over it
    julia> oplot(x, x -> x^3 + x^2 + x)
"""
function oplot(args::PlotArg...; kv...)
    create_context(:line, Dict(kv))

    plt.args = append!(plt.args, plot_args(args))

    plot_data()
end

"""
Draw one or more step or staircase plots.

This function can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot
:param where: pre, mid or post, to decide where the step between two y values should be placed

**Usage examples:**

.. code-block:: julia
    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 2 .* x .+ 4
    julia> # Plot x and y
    julia> step(x, y)
    julia> # Plot x and a callable
    julia> step(x, x -> x^3 + x^2 + x)
    julia> # Plot y, using its indices for the x values
    julia> step(y)
    julia> # Use next y step directly after x each position
    julia> step(y, where="pre")
    julia> # Use next y step between two x positions
    julia> step(y, where="mid")
    julia> # Use next y step immediately before next x position
    julia> step(y, where="post")
"""
function step(args...; kv...)
    create_context(:step, Dict(kv))

    plt.args = plot_args(args, fmt=:xyac)

    plot_data()
end

"""
Draw one or more scatter plots.

This function can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

Additional to x and y values, you can provide values for the markers'
size and color. Size values will determine the marker size in percent of
the regular size, and color values will be used in combination with the
current colormap.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 0.2 .* x .+ 0.4
    julia> # Plot x and y
    julia> scatter(x, y)
    julia> # Plot x and a callable
    julia> scatter(x, x -> 0.2 * x + 0.4)
    julia> # Plot y, using its indices for the x values
    julia> scatter(y)
    julia> # Plot a diagonal with increasing size and color
    julia> x = LinRange(0, 1, 11)
    julia> y = LinRange(0, 1, 11)
    julia> s = LinRange(50, 400, 11)
    julia> c = LinRange(0, 255, 11)
    julia> scatter(x, y, s, c)
"""
function scatter(args...; kv...)
    create_context(:scatter, Dict(kv))

    plt.args = plot_args(args, fmt=:xyac)

    plot_data()
end

"""
Draw a stem plot.

This function can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 0.2 .* x .+ 0.4
    julia> # Plot x and y
    julia> stem(x, y)
    julia> # Plot x and a callable
    julia> stem(x, x -> x^3 + x^2 + x + 6)
    julia> # Plot y, using its indices for the x values
    julia> stem(y)
"""
function stem(args...; kv...)
    create_context(:stem, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

function barcoordinates(heights; barwidth=0.8, baseline=0.0, kv...)
    n = length(heights)
    halfw = barwidth/2
    wc = zeros(2n)
    hc  = zeros(2n)
    for (i, value) in enumerate(heights)
        wc[2i-1] = i - halfw
        wc[2i]   = i + halfw
        hc[2i-1] = baseline
        hc[2i]   = value
    end
    (wc, hc)
end

"""
Draw a bar plot.

If no specific labels are given, the axis is labelled with integer
numbers starting from 1.

Use the keyword arguments **barwidth**, **baseline** or **horizontal**
to modify the default width of the bars (by default 0.8 times the separation
between bars), the baseline value (by default zero), or the direction of
the bars (by default vertical).

:param labels: the labels of the bars
:param heights: the heights of the bars

**Usage examples:**

.. code-block:: julia

    julia> # World population by continents (millions)
    julia> population = Dict("Africa" => 1216,
                             "America" => 1002,
                             "Asia" => 4436,
                             "Europe" => 739,
                             "Oceania" => 38)
    julia> barplot(keys(population), values(population))
    julia> # Horizontal bar plot
    julia> barplot(keys(population), values(population), horizontal=true)
"""
function barplot(labels, heights; kv...)
    kv = Dict(kv)
    wc, hc = barcoordinates(heights; kv...)
    horizontal = pop!(kv, :horizontal, false)
    create_context(:bar, kv)
    if horizontal
        plt.args = [(hc, wc, Nothing, Nothing, "")]
        yticks(1,1)
        yticklabels(string.(labels))
    else
        plt.args = [(wc, hc, Nothing, Nothing, "")]
        xticks(1,1)
        xticklabels(string.(labels))
    end

    plot_data()
end

barplot(heights; kv...) = barplot(string.(1:length(heights)), heights; kv...)

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

"""
Draw a histogram.

If **nbins** is **Nothing** or 0, this function computes the number of
bins as 3.3 * log10(n) + 1,  with n as the number of elements in x,
otherwise the given number of bins is used for the histogram.

:param x: the values to draw as histogram
:param num_bins: the number of bins in the histogram

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = 2 .* rand(100) .- 1
    julia> # Draw the histogram
    julia> histogram(x)
    julia> # Draw the histogram with 19 bins
    julia> histogram(x, nbins=19)
"""
function histogram(x; kv...)
    create_context(:hist, Dict(kv))

    nbins = get(plt.kvs, :nbins, 0)
    x, y = hist(x, nbins)
    plt.args = [(x, y, Nothing, Nothing, "")]

    plot_data()
end

"""
Draw a polar histogram.

If **nbins** is **Nothing** or 0, this function computes the number of
bins as 3.3 * log10(n) + 1,  with n as the number of elements in x,
otherwise the given number of bins is used for the histogram.

:param x: the values to draw as a polar histogram
:param num_bins: the number of bins in the polar histogram

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = 2 .* rand(100) .- 1
    julia> # Draw the polar histogram
    julia> polarhistogram(x, alpha=0.5)
    julia> # Draw the polar histogram with 19 bins
    julia> polarhistogram(x, nbins=19, alpha=0.5)
"""
function polarhistogram(x; kv...)
    create_context(:polarhist, Dict(kv))

    nbins = get(plt.kvs, :nbins, 0)
    x, y = hist(x, nbins)
    plt.args = [(x, y, Nothing, Nothing, "")]

    plot_data()
end

"""
Draw a contour plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a contour plot. It can receive one
or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the contour plot
    julia> contour(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the contour plot
    julia> contour(x, y, z)
    julia> # Draw the contour plot using a callable
    julia> contour(x, y, (x,y) -> sin(x) + cos(y))
"""
function contour(args...; kv...)
    create_context(:contour, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Draw a filled contour plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a filled contour plot. It can
receive one or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the contour plot
    julia> contourf(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the contour plot
    julia> contourf(x, y, z)
    julia> # Draw the contour plot using a callable
    julia> contourf(x, y, (x,y) -> sin(x) + cos(y))
"""
function contourf(args...; kv...)
    create_context(:contourf, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Draw a hexagon binning plot.

This function uses hexagonal binning and the the current colormap to
display a series of points. It  can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = randn(100000)
    julia> y = randn(100000)
    julia> # Draw the hexbin plot
    julia> hexbin(x, y)
"""
function hexbin(args...; kv...)
    create_context(:hexbin, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

"""
Draw a heatmap.

This function uses the current colormap to display a two-dimensional
array as a heatmap. The array is drawn with its first value in the bottom
left corner, so in some cases it may be neccessary to flip the columns
(see the example below).

By default the function will use the column and row indices for the x- and
y-axes, respectively, so setting the axis limits is recommended. Also note that the
values in the array must lie within the current z-axis limits so it may
be neccessary to adjust these limits or clip the range of array values.

:param data: the heatmap data

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the heatmap
    julia> heatmap(z)
"""
function heatmap(D; kv...)
    create_context(:heatmap, Dict(kv))

    if ndims(D) == 2
        z = D'
        width, height = size(z)

        plt.args = [(1:width, 1:height, z, Nothing, "")]

        plot_data()
    else
        error("expected 2-D array")
    end
end

function heatmap(x, y, z; kv...)
    create_context(:nonuniformheatmap, Dict(kv))

    if ndims(z) == 2
        plt.args = [(x, y, z', Nothing, "")]

        plot_data()
    else
        error("expected 2-D array")
    end
end

function polarheatmap(D; kv...)
    create_context(:polarheatmap, Dict(kv))

    if ndims(D) == 2
        z = D'
        width, height = size(z)

        plt.args = [(1:width, 1:height, z, Nothing, "")]

        plot_data()
    else
        error("expected 2-D array")
    end
end

function nonuniformpolarheatmap(x, y, z; kv...)
    create_context(:nonuniformpolarheatmap, Dict(kv))

    if ndims(z) == 2
        plt.args = [(x, y, z', Nothing, "")]

        plot_data()
    else
        error("expected 2-D array")
    end
end

"""
Draw a three-dimensional wireframe plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a wireframe plot. It can receive one
or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the wireframe plot
    julia> wireframe(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the wireframe plot
    julia> wireframe(x, y, z)
    julia> # Draw the wireframe plot using a callable
    julia> wireframe(x, y, (x,y) -> sin(x) + cos(y))
"""
function wireframe(args...; kv...)
    create_context(:wireframe, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Draw a three-dimensional surface plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a surface plot. It can receive one or
more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the surface plot
    julia> surface(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the surface plot
    julia> surface(x, y, z)
    julia> # Draw the surface plot using a callable
    julia> surface(x, y, (x,y) -> sin(x) + cos(y))
"""
function surface(args...; kv...)
    create_context(:surface, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function volume(V; kv...)
    create_context(:volume, Dict(kv))

    plt.args = [(Nothing, Nothing, V, Nothing, "")]

    plot_data()
end

"""
Draw one or more three-dimensional line plots.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(0, 30, 1000)
    julia> y = cos.(x) .* x
    julia> z = sin.(x) .* x
    julia> # Plot the points
    julia> plot3(x, y, z)
"""
function plot3(args...; kv...)
    create_context(:plot3, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Draw one or more three-dimensional scatter plots.

Additional to x, y and z values, you can provide values for the markers'
color. Color values will be used in combination with the current colormap.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot
:param c: the optional color values to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = 2 .* rand(100) .- 1
    julia> y = 2 .* rand(100) .- 1
    julia> z = 2 .* rand(100) .- 1
    julia> c = 999 .* rand(100) .+ 1
    julia> # Plot the points
    julia> scatter3(x, y, z)
    julia> # Plot the points with colors
    julia> scatter3(x, y, z, c)
"""
function scatter3(args...; kv...)
    create_context(:scatter3, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Redraw current plot

This can be used to update the current plot, after setting some
attributes like the title, axes labels, legend, etc.

**Usage examples:**

.. code-block:: julia-repl

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 2 .* x .+ 4
    julia> # Add title and labels
    julia> title("Example plot")
    julia> xlabel("x")
    julia> ylabel("y")
    julia> # Redraw the plot with the new attributes
    julia> redraw()

"""
function redraw(; kv...)
    create_context(Dict(kv))
    plot_data()
end

"""
Set the plot title.

The plot title is drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param title: the plot title

**Usage examples:**

.. code-block:: julia

    julia> # Set the plot title to "Example Plot"
    julia> title("Example Plot")
    julia> # Clear the plot title
    julia> title("")
"""
function title(s)
    if s != ""
        plt.kvs[:title] = s
    else
        delete!(plt.kvs, :title)
    end
    s
end

"""
Set the x-axis label.

The axis labels are drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param x_label: the x-axis label

**Usage examples:**

.. code-block:: julia

    julia> # Set the x-axis label to "x"
    julia> xlabel("x")
    julia> # Clear the x-axis label
    julia> xlabel("")
"""
function xlabel(s)
    if s != ""
        plt.kvs[:xlabel] = s
    else
        delete!(plt.kvs, :xlabel)
    end
    s
end

"""
Set the y-axis label.

The axis labels are drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param y_label: the y-axis label
"""
function ylabel(s)
    if s != ""
        plt.kvs[:ylabel] = s
    else
        delete!(plt.kvs, :ylabel)
    end
    s
end

"""
Set the legend of the plot.

The plot legend is drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param args: The legend strings

**Usage examples:**

.. code-block:: julia

    julia> # Set the legends to "a" and "b"
    julia> legend("a", "b")
"""
function legend(args::AbstractString...; kv...)
    plt.kvs[:labels] = args
end

"""
Set the limits for the x-axis.

The x-axis limits can either be passed as individual arguments or as a
tuple of (**x_min**, **x_max**). Setting either limit to **Nothing** will
cause it to be automatically determined based on the data, which is the
default behavior.

:param x_min:
	- the x-axis lower limit, or
	- **Nothing** to use an automatic lower limit, or
	- a tuple of both x-axis limits
:param x_max:
	- the x-axis upper limit, or
	- **Nothing** to use an automatic upper limit, or
	- **Nothing** if both x-axis limits were passed as first argument
:param adjust: whether or not the limits may be adjusted

**Usage examples:**

.. code-block:: julia

    julia> # Set the x-axis limits to -1 and 1
    julia> xlim((-1, 1))
    julia> # Reset the x-axis limits to be determined automatically
    julia> xlim()
    julia> # Reset the x-axis upper limit and set the lower limit to 0
    julia> xlim((0, Nothing))
    julia> # Reset the x-axis lower limit and set the upper limit to 1
    julia> xlim((Nothing, 1))
"""
function xlim(a)
    plt.kvs[:xlim] = a
end

"""
Set the limits for the y-axis.

The y-axis limits can either be passed as individual arguments or as a
tuple of (**y_min**, **y_max**). Setting either limit to **Nothing** will
cause it to be automatically determined based on the data, which is the
default behavior.

:param y_min:
	- the y-axis lower limit, or
	- **Nothing** to use an automatic lower limit, or
	- a tuple of both y-axis limits
:param y_max:
	- the y-axis upper limit, or
	- **Nothing** to use an automatic upper limit, or
	- **Nothing** if both y-axis limits were passed as first argument
:param adjust: whether or not the limits may be adjusted

**Usage examples:**

.. code-block:: julia

    julia> # Set the y-axis limits to -1 and 1
    julia> ylim((-1, 1))
    julia> # Reset the y-axis limits to be determined automatically
    julia> ylim()
    julia> # Reset the y-axis upper limit and set the lower limit to 0
    julia> ylim((0, Nothing))
    julia> # Reset the y-axis lower limit and set the upper limit to 1
    julia> ylim((Nothing, 1))
"""
function ylim(a)
    plt.kvs[:ylim] = a
end

"""
Save the current figure to a file.

This function draw the current figure using one of GR's workstation types
to create a file of the given name. Which file types are supported depends
on the installed workstation types, but GR usually is built with support
for .png, .jpg, .pdf, .ps, .gif and various other file formats.

:param filename: the filename the figure should be saved to

**Usage examples:**

.. code-block:: julia

    julia> # Create a simple plot
    julia> x = 1:100
    julia> plot(x, 1 ./ (x .+ 1))
    julia> # Save the figure to a file
    julia> savefig("example.png")
"""
function savefig(filename; kv...)
    global plt
    merge!(plt.kvs, Dict(kv))
    GR.beginprint(filename)
    plot_data(false)
    GR.endprint()
end

function meshgrid(vx, vy)
    [x for x in vx, y in vy], [y for x in vx, y in vy]
end

function meshgrid(vx, vy, vz)
    [x for x in vx, y in vy, z in vz], [y for x in vx, y in vy, z in vz], [z for x in vx, y in vy, z in vz]
end

function peaks(n=49)
    x = LinRange(-3, 3, n)
    y = LinRange(-3, 3, n)'
    3 * (1 .- x).^2 .* exp.(-(x.^2) .- (y.+1).^2) .- 10*(x/5 .- x.^3 .- y.^5) .* exp.(-x.^2 .- y.^2) .- 1/3 * exp.(-(x.+1).^2 .- y.^2)
end

"""
Draw an image.

This function can draw an image either from reading a file or using a
two-dimensional array and the current colormap.

:param image: an image file name or two-dimensional array

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw an image from a 2d array
    julia> imshow(z)
    julia> # Draw an image from a file
    julia> imshow("example.png")
"""
function imshow(I; kv...)
    create_context(:imshow, Dict(kv))

    plt.args = [(Nothing, Nothing, Nothing, I, "")]

    plot_data()
end

"""
Draw an isosurface.

This function can draw an image either from reading a file or using a
two-dimensional array and the current colormap. Values greater than the
isovalue will be seen as outside the isosurface, while values less than
the isovalue will be seen as inside the isosurface.

:param v: the volume data
:param isovalue: the isovalue

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> s = LinRange(-1, 1, 40)
    julia> v = 1 .- (s .^ 2 .+ (s .^ 2)' .+ reshape(s,1,1,:) .^ 2) .^ 0.5
    julia> # Draw an image from a 2d array
    julia> isosurface(v, isovalue=0.2)
"""
function isosurface(V; kv...)
    create_context(:isosurface, Dict(kv))

    plt.args = [(Nothing, Nothing, Nothing, V, "")]

    plot_data()
end

function cart2sph(x, y, z)
    azimuth = atan.(y, x)
    elevation = atan.(z, sqrt.(x.^2 + y.^2))
    r = sqrt.(x.^2 + y.^2 + z.^2)
    azimuth, elevation, r
end

function sph2cart(azimuth, elevation, r)
    x = r .* cos.(elevation) .* cos.(azimuth)
    y = r .* cos.(elevation) .* sin.(azimuth)
    z = r .* sin.(elevation)
    x, y, z
end

"""
Draw one or more polar plots.

This function can receive one or more of the following:

- angle values and radius values, or
- angle values and a callable to determine radius values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> angles = LinRange(0, 2pi, 40)
    julia> radii = LinRange(0, 2, 40)
    julia> # Plot angles and radii
    julia> polar(angles, radii)
    julia> # Plot angles and a callable
    julia> polar(angles, r -> cos(r) ^ 2)
"""
function polar(args...; kv...)
    create_context(:polar, Dict(kv))

    plt.args = plot_args(args)

    plot_data()
end

"""
Draw a triangular surface plot.

This function uses the current colormap to display a series of points
as a triangular surface plot. It will use a Delaunay triangulation to
interpolate the z values between x and y values. If the series of points
is concave, this can lead to interpolation artifacts on the edges of the
plot, as the interpolation may occur in very acute triangles.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the triangular surface plot
    julia> trisurf(x, y, z)
"""
function trisurf(args...; kv...)
    create_context(:trisurf, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

"""
Draw a triangular contour plot.

This function uses the current colormap to display a series of points
as a triangular contour plot. It will use a Delaunay triangulation to
interpolate the z values between x and y values. If the series of points
is concave, this can lead to interpolation artifacts on the edges of the
plot, as the interpolation may occur in very acute triangles.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) + cos.(y)
    julia> # Draw the triangular contour plot
    julia> tricont(x, y, z)
"""
function tricont(args...; kv...)
    create_context(:tricont, Dict(kv))

    plt.args = plot_args(args, fmt=:xyzc)

    plot_data()
end

function shade(args...; kv...)
    create_context(:shade, Dict(kv))

    plt.args = plot_args(args, fmt=:xys)

    plot_data()
end

function setpanzoom(x, y, zoom)
    global ctx

    plt.kvs = copy(ctx)
    plt.kvs[:panzoom] = (x, y, zoom)

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
    catch
        true
    end
end

end # module
