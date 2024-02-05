"""
    GR is a universal framework for cross-platform visualization applications.
    It offers developers a compact, portable and consistent graphics library
    for their programs. Applications range from publication quality 2D graphs
    to the representation of complex 3D scenes.

    See https://gr-framework.org/julia.html for full documentation.

    Basic usage:
    ```julia
    using GR
    GR.init() # optional
    plot(
        [0, 0.2, 0.4, 0.6, 0.8, 1.0],
        [0.3, 0.5, 0.4, 0.2, 0.6, 0.7]
    )
    # GR.show() # Use if in a Jupyter Notebook
    ```
"""
module GR

@static if isdefined(Base, :Experimental) &&
           isdefined(Base.Experimental, Symbol("@optlevel"))
    Base.Experimental.@optlevel 1
end

import Base64
import Libdl

export
  init,
  initgr,
  opengks,
  closegks,
  inqdspsize,
  openws,
  closews,
  activatews,
  deactivatews,
  clearws,
  updatews,
  polyline,
  polymarker,
  text,
  inqtext,
  textx,
  inqtextx,
  fillarea,
  cellarray,
  nonuniformcellarray,
  polarcellarray,
  nonuniformpolarcellarray,
  gdp,
  path,
  spline,
  gridit,
  setlinetype,
  setlinewidth,
  setlinecolorind,
  setmarkertype,
  setmarkersize,
  setmarkercolorind,
  settextfontprec,
  setcharexpan,
  setcharspace,
  settextcolorind,
  setcharheight,
  inqcharheight,
  setcharup,
  settextpath,
  settextalign,
  setfillintstyle,
  setfillstyle,
  setfillcolorind,
  setcolorrep,
  setscale,
  inqscale,
  setwindow,
  inqwindow,
  setviewport,
  inqviewport,
  selntran,
  setclip,
  setwswindow,
  setwsviewport,
  createseg,
  copyseg,
  redrawseg,
  setsegtran,
  closeseg,
  samplelocator,
  emergencyclosegks,
  updategks,
  setspace,
  textext,
  inqtextext,
  axes2d, # to avoid WARNING: both GR and Base export "axes"
  axeslbl,
  grid,
  grid3d,
  verrorbars,
  herrorbars,
  polyline3d,
  polymarker3d,
  axes3d,
  settitles3d,
  titles3d,
  surface,
  volume,
  contour,
  hexbin,
  setcolormap,
  colorbar,
  inqcolor,
  inqcolorfromrgb,
  hsvtorgb,
  tick,
  validaterange,
  adjustlimits,
  adjustrange,
  beginprint,
  beginprintext,
  endprint,
  ndctowc,
  wctondc,
  wc3towc,
  drawrect,
  fillrect,
  drawarc,
  fillarc,
  drawpath,
  setarrowstyle,
  setarrowsize,
  drawarrow,
  readimage,
  drawimage,
  importgraphics,
  setshadow,
  settransparency,
  setcoordxform,
  begingraphics,
  endgraphics,
  getgraphics,
  drawgraphics,
  startlistener,
  mathtex,
  inqmathtex,
  selectcontext,
  destroycontext,
  delaunay,
  interp2,
  trisurface,
  tricontour,
# gradient, # deprecated, but still in Base
  quiver,
  reducepoints,
  version,
  check_for_updates,
  openmeta,
  sendmeta,
  sendmetaref,
  closemeta,
  grplot,
  shadepoints,
  shadelines,
  setcolormapfromrgb,
  setborderwidth,
  setbordercolorind,
  setprojectiontype,
  setperspectiveprojection,
  setorthographicprojection,
  settransformationparameters,
  setresamplemethod,
  setwindow3d,
  setspace3d,
  text3d,
  inqtext3d,
  settextencoding,
  inqtextencoding,
  loadfont,
  inqvpsize,
  setpicturesizeforvolume,
  inqtransformationparameters,
  polygonmesh3d,
  setscientificformat,
  setresizebehaviour,
  inqprojectiontype,
  setmathfont,
  inqmathfont,
  setclipregion,
  inqclipregion,
  # Convenience functions
  jlgr,
  colormap,
  figure,
  kvs,
  gcf,
  hold,
  usecolorscheme,
  subplot,
  plot,
  oplot,
  stairs,
  scatter,
  stem,
  barplot,
  histogram,
  polarhistogram,
  contourf,
  heatmap,
  polarheatmap,
  wireframe,
  plot3,
  scatter3,
  redraw,
  title,
  xlabel,
  ylabel,
  drawgrid,
  xticks,
  yticks,
  zticks,
  xticklabels,
  yticklabels,
  legend,
  xlim,
  ylim,
  savefig,
  meshgrid,
  peaks,
  imshow,
  isosurface,
  cart2sph,
  sph2cart,
  polar,
  trisurf,
  tricont,
  shade,
  panzoom,
  setpanzoom,
  libGR3,
  gr3,
  libGRM,
  isinline,
  inline,
  displayname,
  mainloop

const ENCODING_LATIN1 = 300
const ENCODING_UTF8 = 301

const display_name = Ref("")
const mime_type = Ref("")
const file_path = Ref("")
const figure_count = Ref(-1)
const send_c = Ref(C_NULL)
const recv_c = Ref(C_NULL)
const text_encoding = Ref(ENCODING_UTF8)
const check_env = Ref(true)

isijulia() = isdefined(Main, :IJulia) && Main.IJulia isa Module && isdefined(Main.IJulia, :clear_output)
isatom() = isdefined(Main, :Atom) && Main.Atom isa Module && Main.Atom.isconnected() && (isdefined(Main.Atom, :PlotPaneEnabled) ? Main.Atom.PlotPaneEnabled[] : true)
ispluto() = isdefined(Main, :PlutoRunner) && Main.PlutoRunner isa Module
isvscode() = isdefined(Main, :VSCodeServer) && Main.VSCodeServer isa Module && (isdefined(Main.VSCodeServer, :PLOT_PANE_ENABLED) ? Main.VSCodeServer.PLOT_PANE_ENABLED[] : true)

setraw!(raw) = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, raw)

include("preferences.jl")

# Load function pointer caching mechanism
include("funcptrs.jl")


"""
function set_callback()
    callback_c = @cfunction(callback, Cstring, (Cstring, ))
    ccall(libGR_ptr(:gr_setcallback),
          Nothing,
          (Ptr{Cvoid}, ),
          callback_c)
end
"""

"""
    init(always::Bool = false)

    Initialize GR's environmental variables before plotting and ensure that the
    binary shared libraries are loaded. Initialization usually only needs to be
    done once, but reinitialized may be required when settings change.

    The `always` argument is true if initialization should be forced in the
    current and subsequent calls. It is `false` by default so that
    initialization only is done once.

    # Extended Help

    Environmental variables which influence `init`:
    GRDISPLAY - if "js" or "pluto", javascript support is initialized
    GKS_NO_GUI - no initialization is done
    GKS_IGNORE_ENCODING - Force use of UTF-8 for font encoding, ignore GKS_ENCODING

    Environmental variables set by `init`:
    GKS_FONTPATH - path to GR fonts, often the same as GRDIR
    GKS_USE_CAIRO_PNG
    GKSwstype - Graphics workstation type, see help for `openws`
    GKS_QT - Command to start QT backend via gksqt executable
    GKS_ENCODING - Sets the text encoding (e.g. Latin1 or UTF-8)
"""
function init(always::Bool = false)
    if !libs_loaded[]
        load_libs(always)
        return
    end
    if check_env[] || always
        haskey(ENV, "GKS_FONTPATH") || get!(ENV, "GKS_FONTPATH", GRPreferences.grdir[])
        ENV["GKS_USE_CAIRO_PNG"] = "true"
        if "GRDISPLAY" in keys(ENV)
            display_name[] = ENV["GRDISPLAY"]
            if display_name[] == "js" || display_name[] == "pluto" || display_name[] == "js-server"
                send_c[], recv_c[] = js.initjs()
            elseif display_name[] == "plot" || display_name[] == "edit"
                ENV["GR_PLOT"] = if Sys.iswindows()
                    "set PATH=$(GRPreferences.libpath[]) & \"$(GRPreferences.grplot[])\" --listen"
                else
                    key = Sys.isapple() ? "DYLD_FALLBACK_LIBRARY_PATH" : "LD_LIBRARY_PATH"
                    "env $key=$(GRPreferences.libpath[]) $(GRPreferences.grplot[]) --listen"
                end
                GR.startlistener()
                ENV["GKS_WSTYPE"] = "nul"
            end
            @debug "Found GRDISPLAY in ENV" display_name[]
        elseif "GKS_NO_GUI" in keys(ENV)
            @debug "Found GKS_NO_GUI in ENV, returning"
            return
        elseif "GKS_WSTYPE" in keys(ENV)
            mime_type[] = ""
            @debug "Force user-defined output type" ENV["GKS_WSTYPE"]
        elseif isijulia() || ispluto() || isvscode() || isatom()
            mime_type[] = "svg"
            file_path[] = tempname() * ".svg"
            ENV["GKSwstype"] = "svg"
            ENV["GKS_FILEPATH"] = file_path[]
            @debug "Found an embedded environment" mime_type[] file_path[] ENV["GKSwstype"] ENV["GKS_FILEPATH"]
        else
            default_wstype = haskey(ENV, "DISPLAY") ? "gksqt" : ""
            haskey(ENV, "GKSwstype") || get!(ENV, "GKSwstype", default_wstype)
            if !haskey(ENV, "GKS_QT")
                ENV["GKS_QT"] = if Sys.iswindows()
                    "set PATH=$(GRPreferences.libpath[]) & \"$(GRPreferences.gksqt[])\""
                else
                    key = Sys.isapple() ? "DYLD_FALLBACK_LIBRARY_PATH" : "LD_LIBRARY_PATH"
                    "env $key=$(GRPreferences.libpath[]) $(GRPreferences.gksqt[])"
                end
            end
            @debug "Artifacts setup" ENV["GKSwstype"] ENV["GKS_QT"]
        end
        if "GKS_IGNORE_ENCODING" in keys(ENV)
            text_encoding[] = ENCODING_UTF8
            @debug "Found GKS_IGNORE_ENCODING in ENV" text_encoding[]
        elseif "GKS_ENCODING" in keys(ENV)
            text_encoding[] = if (enc = ENV["GKS_ENCODING"]) == "latin1" || enc == "latin-1"
                ENCODING_LATIN1
            else
                ENCODING_UTF8
            end
            @debug "Found GKS_ENCODING in ENV" text_encoding[]
        else
            ENV["GKS_ENCODING"] = "utf8"
            @debug "Default GKS_ENCODING" ENV["GKS_ENCODING"]
        end
        check_env[] = always
    end
end

function initgr()
  ccall( libGR_ptr(:gr_initgr),
        Nothing,
        ()
        )
end

function opengks()
  ccall( libGR_ptr(:gr_opengks),
        Nothing,
        ()
        )
end

function closegks()
  ccall( libGR_ptr(:gr_closegks),
        Nothing,
        ()
        )
end

# (Information taken from <https://www.iterm2.com/utilities/imgcat>.)
# tmux requires unrecognized OSC sequences to be wrapped with DCS
# tmux; <sequence> ST, and for all ESCs in <sequence> to be replaced
# with ESC ESC. It only accepts ESC backslash for ST. We use TERM
# instead of TMUX because TERM gets passed through ssh.
function osc_seq()
    if startswith(get(ENV, "TERM", ""), "screen")
        "\033Ptmux;\033\033]"
    else
        "\033]"
    end
end

function st_seq()
    if startswith(get(ENV, "TERM", ""), "screen")
        "\a\033\\"
    else
        "\a"
    end
end

function is_dark_mode()
    try
        setraw!(true)
        print(stdin, "\033]11;?\033\\")
        resp = read(stdin, 24)
        setraw!(false)
        bg = String(resp)[10:23]
        red, green, blue = parse.(Int, rsplit(bg, '/'), base=16) ./ 0xffff
        return 0.3 * red + 0.59 * green + 0.11 * blue < 0.5
    catch e
        setraw!(false)
        return false
    end
end

function inqdspsize()
  mwidth = Cdouble[0]
  mheight = Cdouble[0]
  width = Cint[0]
  height = Cint[0]
  ccall( libGR_ptr(:gr_inqdspsize),
        Nothing,
        (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}),
        mwidth, mheight, width, height)
  return mwidth[1], mheight[1], width[1], height[1]
end

"""
    openws(workstation_id::Int, connection, workstation_type::Int)

Open a graphical workstation.

**Parameters:**

`workstation_id` :
    A workstation identifier.
`connection` :
    A connection identifier.
`workstation_type` :
    The desired workstation type.

Available workstation types:

    +-------------+------------------------------------------------------+
    |            5|Workstation Independent Segment Storage               |
    +-------------+------------------------------------------------------+
    |         7, 8|Computer Graphics Metafile (CGM binary, clear text)   |
    +-------------+------------------------------------------------------+
    |           41|Windows GDI                                           |
    +-------------+------------------------------------------------------+
    |           51|Mac Quickdraw                                         |
    +-------------+------------------------------------------------------+
    |      61 - 64|PostScript (b/w, color)                               |
    +-------------+------------------------------------------------------+
    |     101, 102|Portable Document Format (plain, compressed)          |
    +-------------+------------------------------------------------------+
    |    210 - 213|X Windows                                             |
    +-------------+------------------------------------------------------+
    |          214|Sun Raster file (RF)                                  |
    +-------------+------------------------------------------------------+
    |     215, 218|Graphics Interchange Format (GIF87, GIF89)            |
    +-------------+------------------------------------------------------+
    |          216|Motif User Interface Language (UIL)                   |
    +-------------+------------------------------------------------------+
    |          320|Windows Bitmap (BMP)                                  |
    +-------------+------------------------------------------------------+
    |          321|JPEG image file                                       |
    +-------------+------------------------------------------------------+
    |          322|Portable Network Graphics file (PNG)                  |
    +-------------+------------------------------------------------------+
    |          323|Tagged Image File Format (TIFF)                       |
    +-------------+------------------------------------------------------+
    |          370|Xfig vector graphics file                             |
    +-------------+------------------------------------------------------+
    |          371|Gtk                                                   |
    +-------------+------------------------------------------------------+
    |          380|wxWidgets                                             |
    +-------------+------------------------------------------------------+
    |          381|Qt4                                                   |
    +-------------+------------------------------------------------------+
    |          382|Scaleable Vector Graphics (SVG)                       |
    +-------------+------------------------------------------------------+
    |          390|Windows Metafile                                      |
    +-------------+------------------------------------------------------+
    |          400|Quartz                                                |
    +-------------+------------------------------------------------------+
    |          410|Socket driver                                         |
    +-------------+------------------------------------------------------+
    |          415|0MQ driver                                            |
    +-------------+------------------------------------------------------+
    |          420|OpenGL                                                |
    +-------------+------------------------------------------------------+
    |          430|HTML5 Canvas                                          |
    +-------------+------------------------------------------------------+

"""
function openws(workstation_id::Int, connection, workstation_type::Int)
  ccall( libGR_ptr(:gr_openws),
        Nothing,
        (Int32, Ptr{Cchar}, Int32),
        workstation_id, connection, workstation_type)
end

"""
    closews(workstation_id::Int)

Close the specified workstation.

**Parameters:**

`workstation_id` :
    A workstation identifier.

"""
function closews(workstation_id::Int)
  ccall( libGR_ptr(:gr_closews),
        Nothing,
        (Int32, ),
        workstation_id)
end

"""
    activatews(workstation_id::Int)

Activate the specified workstation.

**Parameters:**

`workstation_id` :
    A workstation identifier.

"""
function activatews(workstation_id::Int)
  ccall( libGR_ptr(:gr_activatews),
        Nothing,
        (Int32, ),
        workstation_id)
end

"""
    deactivatews(workstation_id::Int)

Deactivate the specified workstation.

**Parameters:**

`workstation_id` :
    A workstation identifier.

"""
function deactivatews(workstation_id::Int)
  ccall( libGR_ptr(:gr_deactivatews),
        Nothing,
        (Int32, ),
        workstation_id)
end

function clearws()
  ccall( libGR_ptr(:gr_clearws),
        Nothing,
        ()
        )
end

function updatews()
  ccall( libGR_ptr(:gr_updatews),
        Nothing,
        ()
        )
end

"""
    polyline(x, y)

Draw a polyline using the current line attributes, starting from the
first data point and ending at the last data point.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates

The values for `x` and `y` are in world coordinates. The attributes that
control the appearance of a polyline are linetype, linewidth and color
index.

"""
function polyline(x, y)
  @assert length(x) == length(y)
  n = length(x)
  ccall( libGR_ptr(:gr_polyline),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y))
end

"""
    polymarker(x, y)

Draw marker symbols centered at the given data points.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates

The values for `x` and `y` are in world coordinates. The attributes that
control the appearance of a polymarker are marker type, marker size
scale factor and color index.

"""
function polymarker(x, y)
  @assert length(x) == length(y)
  n = length(x)
  ccall( libGR_ptr(:gr_polymarker),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y))
end

function latin1(string)
  if text_encoding[] == ENCODING_UTF8
    # add null character '\0' for SubString types (see GR.jl SubString issue #336)
    if typeof(string) == SubString{String}
      return string * "\0"
    else
      return string
    end
  end
  b = unsafe_wrap(Array{UInt8,1}, pointer(string), sizeof(string))
  s = zeros(UInt8, sizeof(string) * 2)
  len = 0
  mask = 0
  for c in b
    if mask == -1
      mask = 0
      continue
    end
    if c == 0xce || c == 0xcf
      len += 1
      s[len] = 0x3f
      mask = -1
      continue
    end
    if c != 0xc2 && c != 0xc3
      len += 1
      s[len] = c | mask
    end
    if c == 0xc3
      mask = 0x40
    else
      mask = 0
    end
  end
  return s[1:len]
end

"""
    text(x::Real, y::Real, string)

Draw a text at position `x`, `y` using the current text attributes.

**Parameters:**

`x` :
    The X coordinate of starting position of the text string
`y` :
    The Y coordinate of starting position of the text string
`string` :
    The text to be drawn

The values for `x` and `y` are in normalized device coordinates.
The attributes that control the appearance of text are text font and precision,
character expansion factor, character spacing, text color index, character
height, character up vector, text path and text alignment.

"""
function text(x::Real, y::Real, string)
  ccall( libGR_ptr(:gr_text),
        Nothing,
        (Float64, Float64, Ptr{UInt8}),
        x, y, latin1(string))
end

function inqtext(x, y, string)
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( libGR_ptr(:gr_inqtext),
        Nothing,
        (Float64, Float64, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, latin1(string), tbx, tby)
  return tbx, tby
end

function textx(x::Real, y::Real, string, opts::UInt32)
  ccall( libGR_ptr(:gr_textx),
        Nothing,
        (Float64, Float64, Ptr{UInt8}, UInt32),
        x, y, latin1(string), opts)
end

function inqtextx(x, y, string, opts::UInt32)
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( libGR_ptr(:gr_inqtextx),
        Nothing,
        (Float64, Float64, Ptr{UInt8}, UInt32, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, latin1(string), opts, tbx, tby)
  return tbx, tby
end

"""
    fillarea(x, y)

Allows you to specify a polygonal shape of an area to be filled.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates

The attributes that control the appearance of fill areas are fill area interior
style, fill area style index and fill area color index.

"""
function fillarea(x, y)
  @assert length(x) == length(y)
  n = length(x)
  ccall( libGR_ptr(:gr_fillarea),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y))
end

"""
    cellarray(xmin::Real, xmax::Real, ymin::Real, ymax::Real, dimx::Int, dimy::Int, color)

Display rasterlike images in a device-independent manner. The cell array
function partitions a rectangle given by two corner points into DIMX X DIMY
cells, each of them colored individually by the corresponding color index
of the given cell array.

**Parameters:**

`xmin`, `ymin` :
    Lower left point of the rectangle
`xmax`, `ymax` :
    Upper right point of the rectangle
`dimx`, `dimy` :
    X and Y dimension of the color index array
`color` :
    Color index array

The values for `xmin`, `xmax`, `ymin` and `ymax` are in world coordinates.

"""
function cellarray(xmin::Real, xmax::Real, ymin::Real, ymax::Real, dimx::Int, dimy::Int, color)
  if ndims(color) == 2
    color = reshape(color, dimx * dimy)
  end
  ccall( libGR_ptr(:gr_cellarray),
        Nothing,
        (Float64, Float64, Float64, Float64, Int32, Int32, Int32, Int32, Int32, Int32, Ptr{Int32}),
        xmin, xmax, ymin, ymax, dimx, dimy, 1, 1, dimx, dimy, convert(Vector{Int32}, color))
end

"""
    nonuniformcellarray(x, y, dimx::Int, dimy::Int, color)

Display a two dimensional color index array with nonuniform cell sizes.

**Parameters:**

`x`, `y` :
    X and Y coordinates of the cell edges
`dimx`, `dimy` :
    X and Y dimension of the color index array
`color` :
    Color index array

The values for `x` and `y` are in world coordinates. `x` must contain `dimx` + 1 elements
and `y` must contain `dimy` + 1 elements. The elements i and i+1 are respectively the edges
of the i-th cell in X and Y direction.

"""
function nonuniformcellarray(x, y, dimx::Int, dimy::Int, color)
  @assert dimx <= length(x) <= dimx+1 && dimy <= length(y) <= dimy+1
  if ndims(color) == 2
    color = reshape(color, dimx * dimy)
  end
  nx = dimx == length(x) ? -dimx : dimx
  ny = dimy == length(y) ? -dimy : dimy
  ccall( libGR_ptr(:gr_nonuniformcellarray),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}, Int32, Int32, Int32, Int32, Int32, Int32, Ptr{Int32}),
        convert(Vector{Float64}, x), convert(Vector{Float64}, y), nx, ny, 1, 1, dimx, dimy, convert(Vector{Int32}, color))
end

"""
    polarcellarray(xorg::Real, yorg::Real, phimin::Real, phimax::Real, rmin::Real, rmax::Real, imphi::Int, dimr::Int, color)

Display a two dimensional color index array mapped to a disk using polar
coordinates.

**Parameters:**

`xorg` :
    X coordinate of the disk center in world coordinates
`yorg` :
    Y coordinate of the disk center in world coordinates
`phimin` :
    start angle of the disk sector in degrees
`phimax` :
    end angle of the disk sector in degrees
`rmin` :
    inner radius of the punctured disk in world coordinates
`rmax` :
    outer radius of the punctured disk in world coordinates
`dimiphi`, `dimr` :
    Phi (X) and iR (Y) dimension of the color index array
`color` :
    Color index array

The two dimensional color index array is mapped to the resulting image by
interpreting the X-axis of the array as the angle and the Y-axis as the radius.
The center point of the resulting disk is located at `xorg`, `yorg` and the
radius of the disk is `rmax`.

"""
function polarcellarray(xorg::Real, yorg::Real, phimin::Real, phimax::Real, rmin::Real, rmax::Real,
                        dimphi::Int, dimr::Int, color)
  if ndims(color) == 2
    color = reshape(color, dimphi * dimr)
  end
  ccall( libGR_ptr(:gr_polarcellarray),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64, Int32, Int32, Int32, Int32, Int32, Int32, Ptr{Int32}),
        xorg, yorg, phimin, phimax, rmin, rmax, dimphi, dimr, 1, 1, dimphi, dimr, convert(Vector{Int32}, color))
end

"""
    nonuniformpolarcellarray(x, y, dimx::Int, dimy::Int, color)

Display a two dimensional color index array mapped to a disk using nonuniform
polar coordinates.

**Parameters:**

`x`, `y` :
    X and Y coordinates of the cell edges
`dimx`, `dimy` :
    X and Y dimension of the color index array
`color` :
    Color index array

The two dimensional color index array is mapped to the resulting image by
interpreting the X-axis of the array as the angle and the Y-axis as the radius.

"""
function nonuniformpolarcellarray(x, y, dimx::Int, dimy::Int, color)
  @assert dimx <= length(x) <= dimx+1 && dimy <= length(y) <= dimy+1
  if ndims(color) == 2
    color = reshape(color, dimx * dimy)
  end
  nx = dimx == length(x) ? -dimx : dimx
  ny = dimy == length(y) ? -dimy : dimy
  ccall( libGR_ptr(:gr_nonuniformpolarcellarray),
        Nothing,
        (Float64, Float64, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Int32, Int32, Int32, Int32, Ptr{Int32}),
        0, 0, convert(Vector{Float64}, x), convert(Vector{Float64}, y), nx, ny, 1, 1, dimx, dimy, convert(Vector{Int32}, color))
end

"""
    gdp(x, y, primid, datrec)

Generates a generalized drawing primitive (GDP) of the type you specify,
using specified points and any additional information contained in a data
record.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`primid` :
    Primitive identifier
`datrec` :
    Primitive data record

"""
function gdp(x, y, primid, datrec)
  @assert length(x) == length(y)
  n = length(x)
  ldr = length(datrec)
  ccall( libGR_ptr(:gr_gdp),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Ptr{Int32}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y),
        primid, ldr, convert(Vector{Int32}, datrec))
end

"""
    path(x, y, codes)

Draw paths using the given vertices and path codes.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`codes` :
    A list containing the path codes

The values for `x` and `y` are in world coordinates.
The `codes` describe several path primitives that can be used to create compound paths.

The following path codes are recognized:

+----------+---------------------------------+-------------------+-------------------+
| **Code** | **Description**                 | **x**             | **y**             |
+----------+---------------------------------+-------------------+-------------------+
|     M, m | move                            | x                 | y                 |
+----------+---------------------------------+-------------------+-------------------+
|     L, l | line                            | x                 | y                 |
+----------+---------------------------------+-------------------+-------------------+
|     Q, q | quadratic Bezier                | x1, x2            | y1, y2            |
+----------+---------------------------------+-------------------+-------------------+
|     C, c | cubic Bezier                    | x1, x2, x3        | y1, y2, y3        |
+----------+---------------------------------+-------------------+-------------------+
|     A, a | arc                             | rx, a1, reserved  | ry, a2, reserved  |
+----------+---------------------------------+-------------------+-------------------+
|        Z | close path                      |                   |                   |
+----------+---------------------------------+-------------------+-------------------+
|        S | stroke                          |                   |                   |
+----------+---------------------------------+-------------------+-------------------+
|        s | close path and stroke           |                   |                   |
+----------+---------------------------------+-------------------+-------------------+
|        f | close path and fill             |                   |                   |
+----------+---------------------------------+-------------------+-------------------+
|        F | close path, fill and stroke     |                   |                   |
+----------+---------------------------------+-------------------+-------------------+


- Move: `M`, `m`

   Moves the current position to (`x`, `y`). The new position is either absolute (`M`) or relative to the current
   position (`m`). The initial position of :code:`path` is (0, 0).

   Example:

   >>> path([0.5, -0.1], [0.2, 0.1], "Mm")

   The first move command in this example moves the current position to the absolute coordinates (0.5, 0.2). The
   second move to performs a movement by (-0.1, 0.1) relative to the current position resulting in the point
   (0.4, 0.3).


- Line: `L`, `l`

   Draws a line from the current position to the given position (`x`, `y`). The end point of the line is either
   absolute (`L`) or relative to the current position (`l`). The current position is set to the end point of the
   line.

   Example:

   >>> path([0.1, 0.5, 0.0], [0.1, 0.1, 0.2], "MLlS")

   The first line to command draws a straight line from the current position (0.1, 0.1) to the absolute position
   (0.5, 0.1) resulting in a horizontal line. The second line to command draws a vertical line relative to the
   current position resulting in the end point (0.5, 0.3).


- Quadratic Bezier curve: `Q`, `q`

   Draws a quadratic bezier curve from the current position to the end point (`x2`, `y2`) using (`x1`, `y1`) as the
   control point. Both points are either absolute (`Q`) or relative to the current position (`q`). The current
   position is set to the end point of the bezier curve.

   Example:

   >>> path([0.1, 0.3, 0.5, 0.2, 0.4], [0.1, 0.2, 0.1, 0.1, 0.0], "MQqS")

   This example will generate two bezier curves whose start and end points are each located at y=0.1. As the control
   points are horizontally in the middle of each bezier curve with a higher y value both curves are symmetrical
   and bend slightly upwards in the middle. The current position is set to (0.9, 0.1) at the end.


- Cubic Bezier curve: `C`, `c`

   Draws a cubic bezier curve from the current position to the end point (`x3`, `y3`) using (`x1`, `y1`) and
   (`x2`, `y2`) as the control points. All three points are either absolute (`C`) or relative to the current position
   (`c`). The current position is set to the end point of the bezier curve.

   Example:

   >>> path(
   ...     [0.1, 0.2, 0.3, 0.4, 0.1, 0.2, 0.3],
   ...     [0.1, 0.2, 0.0, 0.1, 0.1, -0.1, 0.0],
   ...     "MCcS"
   ... )

   This example will generate two bezier curves whose start and end points are each located at y=0.1. As the control
   points are equally spaced along the x-axis and the first is above and the second is below the start and end
   points this creates a wave-like shape for both bezier curves. The current position is set to (0.8, 0.1) at the
   end.


- Ellipctical arc: `A`, `a`

   Draws an elliptical arc starting at the current position. The major axis of the ellipse is aligned with the x-axis
   and the minor axis is aligned with the y-axis of the plot. `rx` and `ry` are the ellipses radii along the major
   and minor axis. `a1` and `a2` define the start and end angle of the arc in radians. The current position is set
   to the end point of the arc. If `a2` is greater than `a1` the arc is drawn counter-clockwise, otherwise it is
   drawn clockwise. The `a` and `A` commands draw the same arc. The third coordinates of the `x` and `y` array are
   ignored and reserved for future use.

   Examples:


   >>> path([0.1, 0.2, -3.14159 / 2, 0.0], [0.1, 0.4, 3.14159 / 2, 0.0], "MAS")

   This example draws an arc starting at (0.1, 0.1). As the start angle -pi/2 is smaller than the end angle pi/2 the
   arc is drawn counter-clockwise. In this case the right half of an ellipse with an x radius of 0.2 and a y radius
   of 0.4 is shown. Therefore the current position is set to (0.1, 0.9) at the end.

   >>> path([0.1, 0.2, 3.14159 / 2, 0.0], [0.9, 0.4, -3.14159 / 2, 0.0], "MAS")

   This examples draws the same arc as the previous one. The only difference is that the starting point is now at
   (0.1, 0.9) and the start angle pi/2 is greater than the end angle -pi/2 so that the ellipse arc is drawn
   clockwise. Therefore the current position is set to (0.1, 0.1) at the end.


- Close path: `Z`

   Closes the current path by connecting the current position to the target position of the last move command
   (`m` or `M`) with a straight line. If no move to was performed in this path it connects the current position to
   (0, 0). When the path is stroked this line will also be drawn.


- Stroke path: `S`, `s`

   Strokes the path with the current border width and border color (set with :code:`gr.setborderwidth` and
   :code:`gr.setbordercolorind`). In case of `s` the path is closed beforehand, which is equivalent to `ZS`.


- Fill path: `F`, `f`

   Fills the current path using the even-odd-rule using the current fill color. Filling a path implicitly closes
   the path. The fill color can be set using :code:`gr.setfillcolorind`. In case of `F` the path is also
   stroked using the current border width and color afterwards.

"""
function path(x, y, codes)
  @assert length(x) == length(y)
  n = length(x)
  ccall( libGR_ptr(:gr_path),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Cstring),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), codes)
end

function to_rgb_color(z)
    z = (z .- minimum(z)) ./ (maximum(z) - minimum(z))
    n = length(z)
    rgb = zeros(Int, n)
    for i in 1:n
        rgb[i] = inqcolor(1000 + round(Int, z[i] * 255))
    end
    rgb
end

function polyline(x, y, linewidth, line_z)
    if length(linewidth) == 1
        linewidth = ones(length(x)) .* linewidth
    end
    linewidth = round.(Int, 1000 .* linewidth)
    @assert length(x) == length(y) == length(linewidth) == length(line_z)
    color = to_rgb_color(line_z)
    attributes = vec(hcat(linewidth, color)')
    gdp(x, y, GDP_DRAW_LINES, attributes)
end

function polymarker(x, y, markersize, marker_z)
    if length(markersize) == 1
        markersize = ones(length(x)) .* markersize
    end
    markersize = round.(Int, 1000 .* markersize)
    @assert length(x) == length(y) == length(markersize) == length(marker_z)
    color = to_rgb_color(marker_z)
    attributes = vec(hcat(markersize, color)')
    gdp(x, y, GDP_DRAW_MARKERS, attributes)
end

"""
    spline(x, y, m, method)

Generate a cubic spline-fit, starting from the first data point and
ending at the last data point.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`m` :
    The number of points in the polygon to be drawn (`m` > len(`x`))
`method` :
    The smoothing method

The values for `x` and `y` are in world coordinates. The attributes that
control the appearance of a spline-fit are linetype, linewidth and color
index.

If `method` is > 0, then a generalized cross-validated smoothing spline is calculated.
If `method` is 0, then an interpolating natural cubic spline is calculated.
If `method` is < -1, then a cubic B-spline is calculated.

"""
function spline(x, y, m, method)
  @assert length(x) == length(y)
  n = length(x)
  ccall( libGR_ptr(:gr_spline),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Int32),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), m, method)
end

function gridit(xd, yd, zd, nx, ny)
  @assert length(xd) == length(yd) == length(zd)
  nd = length(xd)
  x = Cdouble[1 : nx ;]
  y = Cdouble[1 : ny ;]
  z = Cdouble[1 : nx*ny ;]
  ccall( libGR_ptr(:gr_gridit),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
        nd, convert(Vector{Float64}, xd), convert(Vector{Float64}, yd), convert(Vector{Float64}, zd), nx, ny, x, y, z)
  return x, y, z
end

"""
    setlinetype(style::Int)

Specify the line style for polylines.

**Parameters:**

`style` :
    The polyline line style

The available line types are:

    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_SOLID             |   1|Solid line                                         |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DASHED            |   2|Dashed line                                        |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DOTTED            |   3|Dotted line                                        |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DASHED_DOTTED     |   4|Dashed-dotted line                                 |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DASH_2_DOT        |  -1|Sequence of one dash followed by two dots          |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DASH_3_DOT        |  -2|Sequence of one dash followed by three dots        |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_LONG_DASH         |  -3|Sequence of long dashes                            |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_LONG_SHORT_DASH   |  -4|Sequence of a long dash followed by a short dash   |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_SPACED_DASH       |  -5|Sequence of dashes double spaced                   |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_SPACED_DOT        |  -6|Sequence of dots double spaced                     |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_DOUBLE_DOT        |  -7|Sequence of pairs of dots                          |
    +---------------------------+----+---------------------------------------------------+
    |LINETYPE_TRIPLE_DOT        |  -8|Sequence of groups of three dots                   |
    +---------------------------+----+---------------------------------------------------+

"""
function setlinetype(style::Int)
  ccall( libGR_ptr(:gr_setlinetype),
        Nothing,
        (Int32, ),
        style)
end

"""
    setlinewidth(width::Real)

Define the line width of subsequent polyline output primitives.

**Parameters:**

`width` :
    The polyline line width scale factor

The line width is calculated as the nominal line width generated
on the workstation multiplied by the line width scale factor.
This value is mapped by the workstation to the nearest available line width.
The default line width is 1.0, or 1 times the line width generated on the graphics device.

"""
function setlinewidth(width::Real)
  ccall( libGR_ptr(:gr_setlinewidth),
        Nothing,
        (Float64, ),
        width)
end

"""
    setlinecolorind(color::Int)

Define the color of subsequent polyline output primitives.

**Parameters:**

`color` :
    The polyline color index (COLOR < 1256)

"""
function setlinecolorind(color::Int)
  ccall( libGR_ptr(:gr_setlinecolorind),
        Nothing,
        (Int32, ),
        color)
end

"""
    setmarkertype(mtype::Int)

Specifiy the marker type for polymarkers.

**Parameters:**

`style` :
    The polymarker marker type

The available marker types are:

    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_DOT               |    1|Smallest displayable dot                        |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_PLUS              |    2|Plus sign                                       |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_ASTERISK          |    3|Asterisk                                        |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_CIRCLE            |    4|Hollow circle                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_DIAGONAL_CROSS    |    5|Diagonal cross                                  |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_CIRCLE      |   -1|Filled circle                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_TRIANGLE_UP       |   -2|Hollow triangle pointing upward                 |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_TRI_UP      |   -3|Filled triangle pointing upward                 |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_TRIANGLE_DOWN     |   -4|Hollow triangle pointing downward               |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_TRI_DOWN    |   -5|Filled triangle pointing downward               |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SQUARE            |   -6|Hollow square                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_SQUARE      |   -7|Filled square                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_BOWTIE            |   -8|Hollow bowtie                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_BOWTIE      |   -9|Filled bowtie                                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_HGLASS            |  -10|Hollow hourglass                                |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_HGLASS      |  -11|Filled hourglass                                |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_DIAMOND           |  -12|Hollow diamond                                  |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_DIAMOND     |  -13|Filled Diamond                                  |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR              |  -14|Hollow star                                     |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_STAR        |  -15|Filled Star                                     |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_TRI_UP_DOWN       |  -16|Hollow triangles pointing up and down overlaid  |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_TRI_RIGHT   |  -17|Filled triangle point right                     |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID_TRI_LEFT    |  -18|Filled triangle pointing left                   |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_HOLLOW PLUS       |  -19|Hollow plus sign                                |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_SOLID PLUS        |  -20|Solid plus sign                                 |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_PENTAGON          |  -21|Pentagon                                        |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_HEXAGON           |  -22|Hexagon                                         |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_HEPTAGON          |  -23|Heptagon                                        |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_OCTAGON           |  -24|Octagon                                         |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR_4            |  -25|4-pointed star                                  |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR_5            |  -26|5-pointed star (pentagram)                      |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR_6            |  -27|6-pointed star (hexagram)                       |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR_7            |  -28|7-pointed star (heptagram)                      |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_STAR_8            |  -29|8-pointed star (octagram)                       |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_VLINE             |  -30|verical line                                    |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_HLINE             |  -31|horizontal line                                 |
    +-----------------------------+-----+------------------------------------------------+
    |MARKERTYPE_OMARK             |  -32|o-mark                                          |
    +-----------------------------+-----+------------------------------------------------+

Polymarkers appear centered over their specified coordinates.

"""
function setmarkertype(mtype::Int)
  ccall( libGR_ptr(:gr_setmarkertype),
        Nothing,
        (Int32, ),
        mtype)
end

"""
    setmarkersize(mtype::Real)

Specify the marker size for polymarkers.

**Parameters:**

`size` :
    Scale factor applied to the nominal marker size

The polymarker size is calculated as the nominal size generated on the graphics device
multiplied by the marker size scale factor.

"""
function setmarkersize(mtype::Real)
  ccall( libGR_ptr(:gr_setmarkersize),
        Nothing,
        (Float64, ),
        mtype)
end

"""
    setmarkercolorind(color::Int)

Define the color of subsequent polymarker output primitives.

**Parameters:**

`color` :
    The polymarker color index (COLOR < 1256)

"""
function setmarkercolorind(color::Int)
  ccall( libGR_ptr(:gr_setmarkercolorind),
        Nothing,
        (Int32, ),
        color)
end

"""
    settextfontprec(font::Int, precision::Int)

Specify the text font and precision for subsequent text output primitives.

**Parameters:**

`font` :
    Text font (see tables below)
`precision` :
    Text precision (see table below)

The available text fonts are:

    +--------------------------------------+-----+
    |FONT_TIMES_ROMAN                      |  101|
    +--------------------------------------+-----+
    |FONT_TIMES_ITALIC                     |  102|
    +--------------------------------------+-----+
    |FONT_TIMES_BOLD                       |  103|
    +--------------------------------------+-----+
    |FONT_TIMES_BOLDITALIC                 |  104|
    +--------------------------------------+-----+
    |FONT_HELVETICA                        |  105|
    +--------------------------------------+-----+
    |FONT_HELVETICA_OBLIQUE                |  106|
    +--------------------------------------+-----+
    |FONT_HELVETICA_BOLD                   |  107|
    +--------------------------------------+-----+
    |FONT_HELVETICA_BOLDOBLIQUE            |  108|
    +--------------------------------------+-----+
    |FONT_COURIER                          |  109|
    +--------------------------------------+-----+
    |FONT_COURIER_OBLIQUE                  |  110|
    +--------------------------------------+-----+
    |FONT_COURIER_BOLD                     |  111|
    +--------------------------------------+-----+
    |FONT_COURIER_BOLDOBLIQUE              |  112|
    +--------------------------------------+-----+
    |FONT_SYMBOL                           |  113|
    +--------------------------------------+-----+
    |FONT_BOOKMAN_LIGHT                    |  114|
    +--------------------------------------+-----+
    |FONT_BOOKMAN_LIGHTITALIC              |  115|
    +--------------------------------------+-----+
    |FONT_BOOKMAN_DEMI                     |  116|
    +--------------------------------------+-----+
    |FONT_BOOKMAN_DEMIITALIC               |  117|
    +--------------------------------------+-----+
    |FONT_NEWCENTURYSCHLBK_ROMAN           |  118|
    +--------------------------------------+-----+
    |FONT_NEWCENTURYSCHLBK_ITALIC          |  119|
    +--------------------------------------+-----+
    |FONT_NEWCENTURYSCHLBK_BOLD            |  120|
    +--------------------------------------+-----+
    |FONT_NEWCENTURYSCHLBK_BOLDITALIC      |  121|
    +--------------------------------------+-----+
    |FONT_AVANTGARDE_BOOK                  |  122|
    +--------------------------------------+-----+
    |FONT_AVANTGARDE_BOOKOBLIQUE           |  123|
    +--------------------------------------+-----+
    |FONT_AVANTGARDE_DEMI                  |  124|
    +--------------------------------------+-----+
    |FONT_AVANTGARDE_DEMIOBLIQUE           |  125|
    +--------------------------------------+-----+
    |FONT_PALATINO_ROMAN                   |  126|
    +--------------------------------------+-----+
    |FONT_PALATINO_ITALIC                  |  127|
    +--------------------------------------+-----+
    |FONT_PALATINO_BOLD                    |  128|
    +--------------------------------------+-----+
    |FONT_PALATINO_BOLDITALIC              |  129|
    +--------------------------------------+-----+
    |FONT_ZAPFCHANCERY_MEDIUMITALIC        |  130|
    +--------------------------------------+-----+
    |FONT_ZAPFDINGBATS                     |  131|
    +--------------------------------------+-----+

The available text precisions are:

    +---------------------------+---+--------------------------------------+
    |TEXT_PRECISION_STRING      |  0|String precision (higher quality)     |
    +---------------------------+---+--------------------------------------+
    |TEXT_PRECISION_CHAR        |  1|Character precision (medium quality)  |
    +---------------------------+---+--------------------------------------+
    |TEXT_PRECISION_STROKE      |  2|Stroke precision (lower quality)      |
    +---------------------------+---+--------------------------------------+

The appearance of a font depends on the text precision value specified.
STRING, CHARACTER or STROKE precision allows for a greater or lesser
realization of the text primitives, for efficiency. STRING is the default
precision for GR and produces the highest quality output.

"""
function settextfontprec(font::Int, precision::Int)
  ccall( libGR_ptr(:gr_settextfontprec),
        Nothing,
        (Int32, Int32),
        font, precision)
end

"""
    setcharexpan(factor::Real)

Set the current character expansion factor (width to height ratio).

**Parameters:**

`factor` :
    Text expansion factor applied to the nominal text width-to-height ratio

`setcharexpan` defines the width of subsequent text output primitives. The expansion
factor alters the width of the generated characters, but not their height. The default
text expansion factor is 1, or one times the normal width-to-height ratio of the text.

"""
function setcharexpan(factor::Real)
  ccall( libGR_ptr(:gr_setcharexpan),
        Nothing,
        (Float64, ),
        factor)
end

function setcharspace(spacing::Real)
  ccall( libGR_ptr(:gr_setcharspace),
        Nothing,
        (Float64, ),
        spacing)
end

"""
    settextcolorind(color::Int)

Sets the current text color index.

**Parameters:**

`color` :
    The text color index (COLOR < 1256)

`settextcolorind` defines the color of subsequent text output primitives.
GR uses the default foreground color (black=1) for the default text color index.

"""
function settextcolorind(color::Int)
  ccall( libGR_ptr(:gr_settextcolorind),
        Nothing,
        (Int32, ),
        color)
end

"""
    setcharheight(height::Real)

Set the current character height.

**Parameters:**

`height` :
    Text height value

`setcharheight` defines the height of subsequent text output primitives. Text height
is defined as a percentage of the default window. GR uses the default text height of
0.027 (2.7% of the height of the default window).

"""
function setcharheight(height::Real)
  ccall( libGR_ptr(:gr_setcharheight),
        Nothing,
        (Float64, ),
        height)
end

function inqcharheight()
  _height = Cdouble[0]
  ccall( libGR_ptr(:gr_inqcharheight),
        Nothing,
        (Ptr{Cdouble}, ),
        _height)
  return _height[1]
end

"""
    setcharup(ux::Real, uy::Real)

Set the current character text angle up vector.

**Parameters:**

`ux`, `uy` :
    Text up vector

`setcharup` defines the vertical rotation of subsequent text output primitives.
The text up vector is initially set to (0, 1), horizontal to the baseline.

"""
function setcharup(ux::Real, uy::Real)
  ccall( libGR_ptr(:gr_setcharup),
        Nothing,
        (Float64, Float64),
        ux, uy)
end

"""
    settextpath(path::Int)

Define the current direction in which subsequent text will be drawn.

**Parameters:**

`path` :
    Text path (see table below)

    +----------------------+---+---------------+
    |TEXT_PATH_RIGHT       |  0|left-to-right  |
    +----------------------+---+---------------+
    |TEXT_PATH_LEFT        |  1|right-to-left  |
    +----------------------+---+---------------+
    |TEXT_PATH_UP          |  2|downside-up    |
    +----------------------+---+---------------+
    |TEXT_PATH_DOWN        |  3|upside-down    |
    +----------------------+---+---------------+

"""
function settextpath(path::Int)
  ccall( libGR_ptr(:gr_settextpath),
        Nothing,
        (Int32, ),
        path)
end

"""
    settextalign(horizontal::Int, vertical::Int)

Set the current horizontal and vertical alignment for text.

**Parameters:**

`horizontal` :
    Horizontal text alignment (see the table below)
`vertical` :
    Vertical text alignment (see the table below)

`settextalign` specifies how the characters in a text primitive will be aligned
in horizontal and vertical space. The default text alignment indicates horizontal left
alignment and vertical baseline alignment.

    +-------------------------+---+----------------+
    |TEXT_HALIGN_NORMAL       |  0|                |
    +-------------------------+---+----------------+
    |TEXT_HALIGN_LEFT         |  1|Left justify    |
    +-------------------------+---+----------------+
    |TEXT_HALIGN_CENTER       |  2|Center justify  |
    +-------------------------+---+----------------+
    |TEXT_HALIGN_RIGHT        |  3|Right justify   |
    +-------------------------+---+----------------+

    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_NORMAL       |  0|                                                |
    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_TOP          |  1|Align with the top of the characters            |
    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_CAP          |  2|Aligned with the cap of the characters          |
    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_HALF         |  3|Aligned with the half line of the characters    |
    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_BASE         |  4|Aligned with the base line of the characters    |
    +-------------------------+---+------------------------------------------------+
    |TEXT_VALIGN_BOTTOM       |  5|Aligned with the bottom line of the characters  |
    +-------------------------+---+------------------------------------------------+

"""
function settextalign(horizontal::Int, vertical::Int)
  ccall( libGR_ptr(:gr_settextalign),
        Nothing,
        (Int32, Int32),
        horizontal, vertical)
end

"""
    setfillintstyle(style::Int)

Set the fill area interior style to be used for fill areas.

**Parameters:**

`style` :
    The style of fill to be used

`setfillintstyle` defines the interior style  for subsequent fill area output
primitives. The default interior style is HOLLOW.

    +---------+---+--------------------------------------------------------------------------------+
    |HOLLOW   |  0|No filling. Just draw the bounding polyline                                     |
    +---------+---+--------------------------------------------------------------------------------+
    |SOLID    |  1|Fill the interior of the polygon using the fill color index                     |
    +---------+---+--------------------------------------------------------------------------------+
    |PATTERN  |  2|Fill the interior of the polygon using the style index as a pattern index       |
    +---------+---+--------------------------------------------------------------------------------+
    |HATCH    |  3|Fill the interior of the polygon using the style index as a cross-hatched style |
    +---------+---+--------------------------------------------------------------------------------+

"""
function setfillintstyle(style::Int)
  ccall( libGR_ptr(:gr_setfillintstyle),
        Nothing,
        (Int32, ),
        style)
end

"""
    setfillstyle(index::Int)

Sets the fill style to be used for subsequent fill areas.

**Parameters:**

`index` :
    The fill style index to be used

`setfillstyle` specifies an index when PATTERN fill or HATCH fill is requested by the
`setfillintstyle` function. If the interior style is set to PATTERN, the fill style
index points to a device-independent pattern table. If interior style is set to HATCH
the fill style index indicates different hatch styles. If HOLLOW or SOLID is specified
for the interior style, the fill style index is unused.

"""
function setfillstyle(index::Int)
  ccall( libGR_ptr(:gr_setfillstyle),
        Nothing,
        (Int32, ),
        index)
end

"""
    setfillcolorind(color::Int)

Sets the current fill area color index.

**Parameters:**

`color` :
    The fill area color index (COLOR < 1256)

`setfillcolorind` defines the color of subsequent fill area output primitives.
GR uses the default foreground color (black=1) for the default fill area color index.

"""
function setfillcolorind(color::Int)
  ccall( libGR_ptr(:gr_setfillcolorind),
        Nothing,
        (Int32, ),
        color)
end

"""
    setcolorrep(index::Int, red::Real, green::Real, blue::Real)

`setcolorrep` allows to redefine an existing color index representation by specifying
an RGB color triplet.

**Parameters:**

`index` :
    Color index in the range 0 to 1256
`red` :
    Red intensity in the range 0.0 to 1.0
`green` :
    Green intensity in the range 0.0 to 1.0
`blue`:
    Blue intensity in the range 0.0 to 1.0

"""
function setcolorrep(index::Int, red::Real, green::Real, blue::Real)
  ccall( libGR_ptr(:gr_setcolorrep),
        Nothing,
        (Int32, Float64, Float64, Float64),
        index, red, green, blue)
end

"""
    setscale(options::Int)

`setscale` sets the type of transformation to be used for subsequent GR output
primitives.

**Parameters:**

`options` :
    Scale specification (see Table below)

    +---------------+--------------------+
    |OPTION_X_LOG   |Logarithmic X-axis  |
    +---------------+--------------------+
    |OPTION_Y_LOG   |Logarithmic Y-axis  |
    +---------------+--------------------+
    |OPTION_Z_LOG   |Logarithmic Z-axis  |
    +---------------+--------------------+
    |OPTION_FLIP_X  |Flip X-axis         |
    +---------------+--------------------+
    |OPTION_FLIP_Y  |Flip Y-axis         |
    +---------------+--------------------+
    |OPTION_FLIP_Z  |Flip Z-axis         |
    +---------------+--------------------+
    |OPTION_X_LOG2  |log2 scaled X-axis  |
    +---------------+--------------------+
    |OPTION_Y_LOG2  |log2 scaled Y-axis  |
    +---------------+--------------------+
    |OPTION_Z_LOG2  |log2 scaled Z-axis  |
    +---------------+--------------------+
    |OPTION_X_LN    |ln scaled X-axis    |
    +---------------+--------------------+
    |OPTION_Y_LN    |ln scaled Y-axis    |
    +---------------+--------------------+
    |OPTION_Z_LN    |ln scaled Z-axis    |
    +---------------+--------------------+

`setscale` defines the current transformation according to the given scale
specification which may be or'ed together using any of the above options. GR uses
these options for all subsequent output primitives until another value is provided.
The scale options are used to transform points from an abstract logarithmic or
semi-logarithmic coordinate system, which may be flipped along each axis, into the
world coordinate system.

Note: When applying a logarithmic transformation to a specific axis, the system
assumes that the axes limits are greater than zero.

"""
function setscale(options::Int)
  scale = ccall( libGR_ptr(:gr_setscale),
                Int32,
                (Int32, ),
                options)
  return scale
end

function inqscale()
  _options = Cint[0]
   ccall( libGR_ptr(:gr_inqscale),
         Nothing,
         (Ptr{Int32}, ),
         _options)
  return _options[1]
end

"""
    setwindow(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

`setwindow` establishes a window, or rectangular subspace, of world coordinates to be
plotted. If you desire log scaling or mirror-imaging of axes, use the SETSCALE function.

**Parameters:**

`xmin` :
    The left horizontal coordinate of the window (`xmin` < `xmax`).
`xmax` :
    The right horizontal coordinate of the window.
`ymin` :
    The bottom vertical coordinate of the window (`ymin` < `ymax`).
`ymax` :
    The top vertical coordinate of the window.

`setwindow` defines the rectangular portion of the World Coordinate space (WC) to be
associated with the specified normalization transformation. The WC window and the
Normalized Device Coordinates (NDC) viewport define the normalization transformation
through which all output primitives are mapped. The WC window is mapped onto the
rectangular NDC viewport which is, in turn, mapped onto the display surface of the
open and active workstation, in device coordinates. By default, GR uses the range
[0,1] x [0,1], in world coordinates, as the normalization transformation window.

"""
function setwindow(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_setwindow),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

function inqwindow()
  _xmin = Cdouble[0]
  _xmax = Cdouble[0]
  _ymin = Cdouble[0]
  _ymax = Cdouble[0]
  ccall( libGR_ptr(:gr_inqwindow),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        _xmin, _xmax, _ymin, _ymax)
  return _xmin[1], _xmax[1], _ymin[1], _ymax[1]
end

"""
    setviewport(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

`setviewport` establishes a rectangular subspace of normalized device coordinates.

**Parameters:**

`xmin` :
    The left horizontal coordinate of the viewport.
`xmax` :
    The right horizontal coordinate of the viewport (0 <= `xmin` < `xmax` <= 1).
`ymin` :
    The bottom vertical coordinate of the viewport.
`ymax` :
    The top vertical coordinate of the viewport (0 <= `ymin` < `ymax` <= 1).

`setviewport` defines the rectangular portion of the Normalized Device Coordinate
(NDC) space to be associated with the specified normalization transformation. The
NDC viewport and World Coordinate (WC) window define the normalization transformation
through which all output primitives pass. The WC window is mapped onto the rectangular
NDC viewport which is, in turn, mapped onto the display surface of the open and active
workstation, in device coordinates.

"""
function setviewport(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_setviewport),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

function inqviewport()
  _xmin = Cdouble[0]
  _xmax = Cdouble[0]
  _ymin = Cdouble[0]
  _ymax = Cdouble[0]
  ccall( libGR_ptr(:gr_inqviewport),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        _xmin, _xmax, _ymin, _ymax)
  return _xmin[1], _xmax[1], _ymin[1], _ymax[1]
end

"""
    selntran(transform::Int)

`selntran` selects a predefined transformation from world coordinates to normalized
device coordinates.

**Parameters:**

`transform` :
    A normalization transformation number.

    +------+----------------------------------------------------------------------------------------------------+
    |     0|Selects the identity transformation in which both the window and viewport have the range of 0 to 1  |
    +------+----------------------------------------------------------------------------------------------------+
    |  >= 1|Selects a normalization transformation as defined by `setwindow` and `setviewport`                  |
    +------+----------------------------------------------------------------------------------------------------+

"""
function selntran(transform::Int)
  ccall( libGR_ptr(:gr_selntran),
        Nothing,
        (Int32, ),
        transform)
end

"""
    setclip(indicator::Int)

Set the clipping indicator.

**Parameters:**

`indicator` :
    An indicator specifying whether clipping is on or off.

    +----+---------------------------------------------------------------+
    |   0|Clipping is off. Data outside of the window will be drawn.     |
    +----+---------------------------------------------------------------+
    |   1|Clipping is on. Data outside of the window will not be drawn.  |
    +----+---------------------------------------------------------------+

`setclip` enables or disables clipping of the image drawn in the current window.
Clipping is defined as the removal of those portions of the graph that lie outside of
the defined viewport. If clipping is on, GR does not draw generated output primitives
past the viewport boundaries. If clipping is off, primitives may exceed the viewport
boundaries, and they will be drawn to the edge of the workstation window.
By default, clipping is on.

"""
function setclip(indicator::Int)
  ccall( libGR_ptr(:gr_setclip),
        Nothing,
        (Int32, ),
        indicator)
end

"""
    setwswindow(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

Set the area of the NDC viewport that is to be drawn in the workstation window.

**Parameters:**

`xmin` :
    The left horizontal coordinate of the workstation window.
`xmax` :
    The right horizontal coordinate of the workstation window (0 <= `xmin` < `xmax` <= 1).
`ymin` :
    The bottom vertical coordinate of the workstation window.
`ymax` :
    The top vertical coordinate of the workstation window (0 <= `ymin` < `ymax` <= 1).

`setwswindow` defines the rectangular area of the Normalized Device Coordinate space
to be output to the device. By default, the workstation transformation will map the
range [0,1] x [0,1] in NDC onto the largest square on the workstation’s display
surface. The aspect ratio of the workstation window is maintained at 1 to 1.

"""
function setwswindow(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_setwswindow),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

"""
    setwsviewport(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

Define the size of the workstation graphics window in meters.

**Parameters:**

`xmin` :
    The left horizontal coordinate of the workstation viewport.
`xmax` :
    The right horizontal coordinate of the workstation viewport.
`ymin` :
    The bottom vertical coordinate of the workstation viewport.
`ymax` :
    The top vertical coordinate of the workstation viewport.

`setwsviewport` places a workstation window on the display of the specified size in
meters. This command allows the workstation window to be accurately sized for a
display or hardcopy device, and is often useful for sizing graphs for desktop
publishing applications.

"""
function setwsviewport(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_setwsviewport),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

function createseg(segment::Int)
  ccall( libGR_ptr(:gr_createseg),
        Nothing,
        (Int32, ),
        segment)
end

function copyseg(segment::Int)
  ccall( libGR_ptr(:gr_copysegws),
        Nothing,
        (Int32, ),
        segment)
end

function redrawseg()
  ccall( libGR_ptr(:gr_redrawsegws),
        Nothing,
        ()
        )
end

function setsegtran(segment::Int, fx::Real, fy::Real, transx::Real, transy::Real, phi::Real, scalex::Real, scaley::Real)
  ccall( libGR_ptr(:gr_setsegtran),
        Nothing,
        (Int32, Float64, Float64, Float64, Float64, Float64, Float64, Float64),
        segment, fx, fy, transx, transy, phi, scalex, scaley)
end

function closeseg()
  ccall( libGR_ptr(:gr_closeseg),
        Nothing,
        ()
        )
end

function samplelocator()
  x = Cdouble[0]
  y = Cdouble[0]
  buttons = Cint[0]
  ccall( libGR_ptr(:gr_samplelocator),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}, Ptr{Int32}),
        x, y, buttons)
  return x[1], y[1], buttons[1]
end

function emergencyclosegks()
  ccall( libGR_ptr(:gr_emergencyclosegks),
        Nothing,
        ()
        )
end

function updategks()
  ccall( libGR_ptr(:gr_updategks),
        Nothing,
        ()
        )
end

"""
    setspace(zmin::Real, zmax::Real, rotation::Int, tilt::Int)

Set the abstract Z-space used for mapping three-dimensional output primitives into
the current world coordinate space.

**Parameters:**

`zmin` :
    Minimum value for the Z-axis.
`zmax` :
    Maximum value for the Z-axis.
`rotation` :
    Angle for the rotation of the X axis, in degrees.
`tilt` :
    Viewing angle of the Z axis in degrees.

`setspace` establishes the limits of an abstract Z-axis and defines the angles for
rotation and for the viewing angle (tilt) of a simulated three-dimensional graph,
used for mapping corresponding output primitives into the current window.
These settings are used for all subsequent three-dimensional output primitives until
other values are specified. Angles of rotation and viewing angle must be specified
between 0° and 90°.

"""
function setspace(zmin::Real, zmax::Real, rotation::Int, tilt::Int)
  space = ccall( libGR_ptr(:gr_setspace),
                Int32,
                (Float64, Float64, Int32, Int32),
                zmin, zmax, rotation, tilt)

  return space
end

"""
    textext(x::Real, y::Real, string)

Draw a text at position `x`, `y` using the current text attributes. Strings can be
defined to create basic mathematical expressions and Greek letters.

**Parameters:**

`x` :
    The X coordinate of starting position of the text string
`y` :
    The Y coordinate of starting position of the text string
`string` :
    The text to be drawn

The values for X and Y are in normalized device coordinates.
The attributes that control the appearance of text are text font and precision,
character expansion factor, character spacing, text color index, character
height, character up vector, text path and text alignment.

The character string is interpreted to be a simple mathematical formula.
The following notations apply:

Subscripts and superscripts: These are indicated by carets ('^') and underscores
('_'). If the sub/superscript contains more than one character, it must be enclosed
in curly braces ('{}').

Fractions are typeset with A '/' B, where A stands for the numerator and B for the
denominator.

To include a Greek letter you must specify the corresponding keyword after a
backslash ('\') character. The text translator produces uppercase or lowercase
Greek letters depending on the case of the keyword.

    +--------+---------+
    |Letter  |Keyword  |
    +--------+---------+
    |Α α     |alpha    |
    +--------+---------+
    |Β β     |beta     |
    +--------+---------+
    |Γ γ     |gamma    |
    +--------+---------+
    |Δ δ     |delta    |
    +--------+---------+
    |Ε ε     |epsilon  |
    +--------+---------+
    |Ζ ζ     |zeta     |
    +--------+---------+
    |Η η     |eta      |
    +--------+---------+
    |Θ θ     |theta    |
    +--------+---------+
    |Ι ι     |iota     |
    +--------+---------+
    |Κ κ     |kappa    |
    +--------+---------+
    |Λ λ     |lambda   |
    +--------+---------+
    |Μ μ     |mu       |
    +--------+---------+
    |Ν ν     |nu       |
    +--------+---------+
    |Ξ ξ     |xi       |
    +--------+---------+
    |Ο ο     |omicron  |
    +--------+---------+
    |Π π     |pi       |
    +--------+---------+
    |Ρ ρ     |rho      |
    +--------+---------+
    |Σ σ     |sigma    |
    +--------+---------+
    |Τ τ     |tau      |
    +--------+---------+
    |Υ υ     |upsilon  |
    +--------+---------+
    |Φ φ     |phi      |
    +--------+---------+
    |Χ χ     |chi      |
    +--------+---------+
    |Ψ ψ     |psi      |
    +--------+---------+
    |Ω ω     |omega    |
    +--------+---------+

For more sophisticated mathematical formulas, you should use the `gr.mathtex`
function.

"""
function textext(x::Real, y::Real, string)
  result = ccall( libGR_ptr(:gr_textext),
                 Int32,
                 (Float64, Float64, Ptr{UInt8}),
                 x, y, latin1(string))

  return result
end

function inqtextext(x::Real, y::Real, string)
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( libGR_ptr(:gr_inqtextext),
        Nothing,
        (Float64, Float64, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, latin1(string), tbx, tby)
  return tbx, tby
end

"""
    axes2d(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real)

Draw X and Y coordinate axes with linearly and/or logarithmically spaced tick marks.

**Parameters:**

`x_tick`, `y_tick` :
    The interval between minor tick marks on each axis.
`x_org`, `y_org` :
    The world coordinates of the origin (point of intersection) of the X
    and Y axes.
`major_x`, `major_y` :
    Unitless integer values specifying the number of minor tick intervals
    between major tick marks. Values of 0 or 1 imply no minor ticks.
    Negative values specify no labels will be drawn for the associated axis.
`tick_size` :
    The length of minor tick marks specified in a normalized device
    coordinate unit. Major tick marks are twice as long as minor tick marks.
    A negative value reverses the tick marks on the axes from inward facing
    to outward facing (or vice versa).

Tick marks are positioned along each axis so that major tick marks fall on the axes
origin (whether visible or not). Major tick marks are labeled with the corresponding
data values. Axes are drawn according to the scale of the window. Axes and tick marks
are drawn using solid lines; line color and width can be modified using the
`setlinetype` and `setlinewidth` functions. Axes are drawn according to
the linear or logarithmic transformation established by the `setscale` function.

"""
function axes2d(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real)
  ccall( libGR_ptr(:gr_axes),
        Nothing,
        (Float64, Float64, Float64, Float64, Int32, Int32, Float64),
        x_tick, y_tick, x_org, y_org, major_x, major_y, tick_size)
end

axes(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real) = axes2d(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real)

"""
    function axeslbl(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real, fpx::Function, fpy::Function)

Draw X and Y coordinate axes with linearly and/or logarithmically spaced tick marks.

Tick marks are positioned along each axis so that major tick marks fall on the
axes origin (whether visible or not). Major tick marks are labeled with the
corresponding data values. Axes are drawn according to the scale of the window.
Axes and tick marks are drawn using solid lines; line color and width can be
modified using the `setlinetype` and `setlinewidth` functions.
Axes are drawn according to the linear or logarithmic transformation established
by the `setscale` function.

**Parameters:**

`x_tick`, `y_tick` :
    The interval between minor tick marks on each axis.
`x_org`, `y_org` :
    The world coordinates of the origin (point of intersection) of the X
    and Y axes.
`major_x`, `major_y` :
    Unitless integer values specifying the number of minor tick intervals
    between major tick marks. Values of 0 or 1 imply no minor ticks.
    Negative values specify no labels will be drawn for the associated axis.
`tick_size` :
    The length of minor tick marks specified in a normalized device
    coordinate unit. Major tick marks are twice as long as minor tick marks.
    A negative value reverses the tick marks on the axes from inward facing
    to outward facing (or vice versa).
`fx`, `fy` :
    Functions that returns a label for a given tick on the X or Y axis.
    Those functions should have the following arguments:
`x`, `y` :
    Normalized device coordinates of the label in X and Y directions.
`svalue` :
    Internal string representation of the text drawn at `(x,y)`.
`value` :
    Floating point representation of the label drawn at `(x,y)`.

"""
function axeslbl(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real, fx::Function, fy::Function)
  fx_c = @cfunction($fx, Int32, (Float64, Float64, Cstring, Float64))
  fy_c = @cfunction($fy, Int32, (Float64, Float64, Cstring, Float64))
  ccall( libGR_ptr(:gr_axeslbl),
        Nothing,
        (Float64, Float64, Float64, Float64, Int32, Int32, Float64, Ptr{Nothing}, Ptr{Nothing}),
        x_tick, y_tick, x_org, y_org, major_x, major_y, tick_size, fx_c, fy_c)
end


"""
    grid(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int)

Draw a linear and/or logarithmic grid.

**Parameters:**

`x_tick`, `y_tick` :
    The length in world coordinates of the interval between minor grid
    lines.
`x_org`, `y_org` :
    The world coordinates of the origin (point of intersection) of the grid.
`major_x`, `major_y` :
    Unitless integer values specifying the number of minor grid lines
    between major grid lines. Values of 0 or 1 imply no grid lines.

Major grid lines correspond to the axes origin and major tick marks whether visible
or not. Minor grid lines are drawn at points equal to minor tick marks. Major grid
lines are drawn using black lines and minor grid lines are drawn using gray lines.

"""
function grid(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int)
  ccall( libGR_ptr(:gr_grid),
        Nothing,
        (Float64, Float64, Float64, Float64, Int32, Int32),
        x_tick, y_tick, x_org, y_org, major_x, major_y)
end

function grid3d(x_tick::Real, y_tick::Real, z_tick::Real, x_org::Real, y_org::Real, z_org::Real, major_x::Int, major_y::Int, major_z::Int)
  ccall( libGR_ptr(:gr_grid3d),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64, Int32, Int32, Int32),
        x_tick, y_tick, z_tick, x_org, y_org, z_org, major_x, major_y, major_z)
end

"""
    verrorbars(px, py, e1, e2)

Draw a standard vertical error bar graph.

**Parameters:**

`px` :
    A list of length N containing the X coordinates
`py` :
    A list of length N containing the Y coordinates
`e1` :
     The absolute values of the lower error bar data
`e2` :
     The absolute values of the upper error bar data

"""
function verrorbars(px, py, e1, e2)
  @assert length(px) == length(py) == length(e1) == length(e2)
  n = length(px)
  ccall( libGR_ptr(:gr_verrorbars),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, e1), convert(Vector{Float64}, e2))
end

"""
    herrorbars(px, py, e1, e2)

Draw a standard horizontal error bar graph.

**Parameters:**

`px` :
    A list of length N containing the X coordinates
`py` :
    A list of length N containing the Y coordinates
`e1` :
     The absolute values of the lower error bar data
`e2` :
     The absolute values of the upper error bar data

"""
function herrorbars(px, py, e1, e2)
  @assert length(px) == length(py) == length(e1) == length(e2)
  n = length(px)
  ccall( libGR_ptr(:gr_herrorbars),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, e1), convert(Vector{Float64}, e2))
end

"""
    polyline3d(px, py, pz)

Draw a 3D curve using the current line attributes, starting from the
first data point and ending at the last data point.

**Parameters:**

`x` :
    A list of length N containing the X coordinates
`y` :
    A list of length N containing the Y coordinates
`z` :
    A list of length N containing the Z coordinates

The values for `x`, `y` and `z` are in world coordinates. The attributes that
control the appearance of a polyline are linetype, linewidth and color
index.

"""
function polyline3d(px, py, pz)
  @assert length(px) == length(py) == length(pz)
  n = length(px)
  ccall( libGR_ptr(:gr_polyline3d),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz))
end

"""
    polymarker3d(px, py, pz)

Draw marker symbols centered at the given 3D data points.

**Parameters:**

`x` :
    A list of length N containing the X coordinates
`y` :
    A list of length N containing the Y coordinates
`z` :
    A list of length N containing the Z coordinates

The values for `x`, `y` and `z` are in world coordinates. The attributes
that control the appearance of a polymarker are marker type, marker size
scale factor and color index.

"""
function polymarker3d(px, py, pz)
  @assert length(px) == length(py) == length(pz)
  n = length(px)
  ccall( libGR_ptr(:gr_polymarker3d),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz))
end

function axes3d(x_tick::Real, y_tick::Real, z_tick::Real, x_org::Real, y_org::Real, z_org::Real, major_x::Int, major_y::Int, major_z::Int, tick_size::Real)
  ccall( libGR_ptr(:gr_axes3d),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64, Int32, Int32, Int32, Float64),
        x_tick, y_tick, z_tick, x_org, y_org, z_org, major_x, major_y, major_z, tick_size)
end

"""
    settitles3d(x_title, y_title, z_title)

Set axis titles to be displayed in subsequent axes calls.

**Parameters:**

`x_title`, `y_title`, `z_title` :
    The text to be displayed on each axis

"""
function settitles3d(x_title, y_title, z_title)
  ccall( libGR_ptr(:gr_settitles3d),
        Nothing,
        (Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}),
        latin1(x_title), latin1(y_title), latin1(z_title))
end

"""
    titles3d(x_title, y_title, z_title)

Display axis titles just outside of their respective axes.

**Parameters:**

`x_title`, `y_title`, `z_title` :
    The text to be displayed on each axis

"""
function titles3d(x_title, y_title, z_title)
  ccall( libGR_ptr(:gr_titles3d),
        Nothing,
        (Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}),
        latin1(x_title), latin1(y_title), latin1(z_title))
end

"""
    surface(px, py, pz, option::Int)

Draw a three-dimensional surface plot for the given data points.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`z` :
    A list of length `len(x)` * `len(y)` or an appropriately dimensioned
    array containing the Z coordinates
`option` :
    Surface display option (see table below)

`x` and `y` define a grid. `z` is a singly dimensioned array containing at least
`nx` * `ny` data points. Z describes the surface height at each point on the grid.
Data is ordered as shown in the following table:

    +------------------+--+--------------------------------------------------------------+
    |LINES             | 0|Use X Y polylines to denote the surface                       |
    +------------------+--+--------------------------------------------------------------+
    |MESH              | 1|Use a wire grid to denote the surface                         |
    +------------------+--+--------------------------------------------------------------+
    |FILLED_MESH       | 2|Applies an opaque grid to the surface                         |
    +------------------+--+--------------------------------------------------------------+
    |Z_SHADED_MESH     | 3|Applies Z-value shading to the surface                        |
    +------------------+--+--------------------------------------------------------------+
    |COLORED_MESH      | 4|Applies a colored grid to the surface                         |
    +------------------+--+--------------------------------------------------------------+
    |CELL_ARRAY        | 5|Applies a grid of individually-colored cells to the surface   |
    +------------------+--+--------------------------------------------------------------+
    |SHADED_MESH       | 6|Applies light source shading to the 3-D surface               |
    +------------------+--+--------------------------------------------------------------+

"""
function surface(px, py, pz, option::Int)
  nx = length(px)
  ny = length(py)
  if isa(pz, Function)
    f = pz
    pz = Float64[f(x,y) for y in py, x in px]
  end
  nz = length(pz)
  if ndims(pz) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(pz) == 2
    out_of_bounds = size(pz)[1] != nx || size(pz)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if ndims(pz) == 2
      pz = reshape(pz, nx * ny)
    end
    ccall( libGR_ptr(:gr_surface),
          Nothing,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz), option)
  else
    error("Arrays have incorrect length or dimension.")
  end
end

"""
    contour(px, py, h, pz, major_h::Int)

Draw contours of a three-dimensional data set whose values are specified over a
rectangular mesh. Contour lines may optionally be labeled.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`h` :
    A list containing the Z coordinate for the height values
`z` :
    A list of length `len(x)` * `len(y)` or an appropriately dimensioned
    array containing the Z coordinates
`major_h` :
    Directs GR to label contour lines. For example, a value of 3 would label
    every third line. A value of 1 will label every line. A value of 0
    produces no labels. To produce colored contour lines, add an offset
    of 1000 to `major_h`.

"""
function contour(px, py, h, pz, major_h::Int)
  nx = length(px)
  ny = length(py)
  nh = length(h)
  if isa(pz, Function)
    f = pz
    pz = Float64[f(x,y) for y in py, x in px]
  end
  nz = length(pz)
  if ndims(pz) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(pz) == 2
    out_of_bounds = size(pz)[1] != nx || size(pz)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if ndims(pz) == 2
      pz = reshape(pz, nx * ny)
    end
    ccall( libGR_ptr(:gr_contour),
          Nothing,
          (Int32, Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, nh, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, h), convert(Vector{Float64}, pz), major_h)
  else
    error("Arrays have incorrect length or dimension.")
  end
end

"""
    contourf(px, py, h, pz, major_h::Int)

Draw filled contours of a three-dimensional data set whose values are
specified over a rectangular mesh.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`h` :
    A list containing the Z coordinate for the height values
`z` :
    A list of length `len(x)` * `len(y)` or an appropriately dimensioned
    array containing the Z coordinates
`major_h` :
    (intended for future use)

"""
function contourf(px, py, h, pz, major_h::Int)
  nx = length(px)
  ny = length(py)
  nh = length(h)
  if isa(pz, Function)
    f = pz
    pz = Float64[f(x,y) for y in py, x in px]
  end
  nz = length(pz)
  if ndims(pz) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(pz) == 2
    out_of_bounds = size(pz)[1] != nx || size(pz)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if ndims(pz) == 2
      pz = reshape(pz, nx * ny)
    end
    ccall( libGR_ptr(:gr_contourf),
          Nothing,
          (Int32, Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, nh, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, h), convert(Vector{Float64}, pz), major_h)
  else
    error("Arrays have incorrect length or dimension.")
  end
end

function hexbin(x, y, nbins)
  @assert length(x) == length(y)
  n = length(x)
  cntmax = ccall( libGR_ptr(:gr_hexbin),
                 Int32,
                 (Int32, Ptr{Float64}, Ptr{Float64}, Int32),
                 n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), nbins)
  return cntmax
end

function setcolormap(index::Int)
  ccall( libGR_ptr(:gr_setcolormap),
        Nothing,
        (Int32, ),
        index)
end

function colorbar()
  ccall( libGR_ptr(:gr_colorbar),
        Nothing,
        ()
        )
end

function inqcolor(color::Int)
  rgb = Cint[0]
  ccall( libGR_ptr(:gr_inqcolor),
        Nothing,
        (Int32, Ptr{Int32}),
        color, rgb)
  return rgb[1]
end

function inqcolorfromrgb(red::Real, green::Real, blue::Real)
  color = ccall( libGR_ptr(:gr_inqcolorfromrgb),
                Int32,
                (Float64, Float64, Float64),
                red, green, blue)
  return color
end

function hsvtorgb(h::Real, s::Real, v::Real)
  r = Cdouble[0]
  g = Cdouble[0]
  b = Cdouble[0]
  ccall( libGR_ptr(:gr_hsvtorgb),
        Nothing,
        (Float64, Float64, Float64, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        h, s, v, r, g, b)
  return r[1], g[1], b[1]
end

function tick(amin::Real, amax::Real)
  return ccall( libGR_ptr(:gr_tick),
               Float64,
               (Float64, Float64),
               amin, amax)
end

function validaterange(amin::Real, amax::Real)
  return ccall( libGR_ptr(:gr_validaterange),
               Int32,
               (Float64, Float64),
               amin, amax)
end

function adjustlimits(amin::Real, amax::Real)
  _amin = Cdouble[amin]
  _amax = Cdouble[amax]
  ccall( libGR_ptr(:gr_adjustlimits),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}),
        _amin, _amax)
  return _amin[1], _amax[1]
end

function adjustrange(amin::Real, amax::Real)
  _amin = Cdouble[amin]
  _amax = Cdouble[amax]
  ccall( libGR_ptr(:gr_adjustrange),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}),
        _amin, _amax)
  return _amin[1], _amax[1]
end

"""
    beginprint(pathname)

Open and activate a print device.

**Parameters:**

`pathname` :
    Filename for the print device.

`beginprint` opens an additional graphics output device. The device type is obtained
from the given file extension. The following file types are supported:

    +-------------+---------------------------------------+
    |.ps, .eps    |PostScript                             |
    +-------------+---------------------------------------+
    |.pdf         |Portable Document Format               |
    +-------------+---------------------------------------+
    |.bmp         |Windows Bitmap (BMP)                   |
    +-------------+---------------------------------------+
    |.jpeg, .jpg  |JPEG image file                        |
    +-------------+---------------------------------------+
    |.png         |Portable Network Graphics file (PNG)   |
    +-------------+---------------------------------------+
    |.tiff, .tif  |Tagged Image File Format (TIFF)        |
    +-------------+---------------------------------------+
    |.fig         |Xfig vector graphics file              |
    +-------------+---------------------------------------+
    |.svg         |Scalable Vector Graphics               |
    +-------------+---------------------------------------+
    |.wmf         |Windows Metafile                       |
    +-------------+---------------------------------------+

"""
function beginprint(pathname)
  ccall( libGR_ptr(:gr_beginprint),
        Nothing,
        (Ptr{Cchar}, ),
        pathname)
end

"""
    beginprintext(pathname, mode, fmt, orientation)

Open and activate a print device with the given layout attributes.

**Parameters:**

`pathname` :
    Filename for the print device.
`mode` :
    Output mode (Color, GrayScale)
`fmt` :
    Output format (see table below)
`orientation` :
    Page orientation (Landscape, Portait)

The available formats are:

    +-----------+---------------+
    |A4         |0.210 x 0.297  |
    +-----------+---------------+
    |B5         |0.176 x 0.250  |
    +-----------+---------------+
    |Letter     |0.216 x 0.279  |
    +-----------+---------------+
    |Legal      |0.216 x 0.356  |
    +-----------+---------------+
    |Executive  |0.191 x 0.254  |
    +-----------+---------------+
    |A0         |0.841 x 1.189  |
    +-----------+---------------+
    |A1         |0.594 x 0.841  |
    +-----------+---------------+
    |A2         |0.420 x 0.594  |
    +-----------+---------------+
    |A3         |0.297 x 0.420  |
    +-----------+---------------+
    |A5         |0.148 x 0.210  |
    +-----------+---------------+
    |A6         |0.105 x 0.148  |
    +-----------+---------------+
    |A7         |0.074 x 0.105  |
    +-----------+---------------+
    |A8         |0.052 x 0.074  |
    +-----------+---------------+
    |A9         |0.037 x 0.052  |
    +-----------+---------------+
    |B0         |1.000 x 1.414  |
    +-----------+---------------+
    |B1         |0.500 x 0.707  |
    +-----------+---------------+
    |B10        |0.031 x 0.044  |
    +-----------+---------------+
    |B2         |0.500 x 0.707  |
    +-----------+---------------+
    |B3         |0.353 x 0.500  |
    +-----------+---------------+
    |B4         |0.250 x 0.353  |
    +-----------+---------------+
    |B6         |0.125 x 0.176  |
    +-----------+---------------+
    |B7         |0.088 x 0.125  |
    +-----------+---------------+
    |B8         |0.062 x 0.088  |
    +-----------+---------------+
    |B9         |0.044 x 0.062  |
    +-----------+---------------+
    |C5E        |0.163 x 0.229  |
    +-----------+---------------+
    |Comm10E    |0.105 x 0.241  |
    +-----------+---------------+
    |DLE        |0.110 x 0.220  |
    +-----------+---------------+
    |Folio      |0.210 x 0.330  |
    +-----------+---------------+
    |Ledger     |0.432 x 0.279  |
    +-----------+---------------+
    |Tabloid    |0.279 x 0.432  |
    +-----------+---------------+

"""
function beginprintext(pathname, mode, fmt, orientation)
  ccall( libGR_ptr(:gr_beginprintext),
        Nothing,
        (Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}),
        pathname, mode, fmt, orientation)
end

function endprint()
  ccall( libGR_ptr(:gr_endprint),
        Nothing,
        ()
        )
end

function ndctowc(x::Real, y::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  ccall( libGR_ptr(:gr_ndctowc),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}),
        _x, _y)
  return _x[1], _y[1]
end

function wctondc(x::Real, y::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  ccall( libGR_ptr(:gr_wctondc),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}),
        _x, _y)
  return _x[1], _y[1]
end

function wc3towc(x::Real, y::Real, z::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  _z = Cdouble[z]
  ccall( libGR_ptr(:gr_wc3towc),
        Nothing,
        (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        _x, _y, _z)
  return _x[1], _y[1], _z[1]
end

"""
    drawrect(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

Draw a rectangle using the current line attributes.

**Parameters:**

`xmin` :
    Lower left edge of the rectangle
`xmax` :
    Lower right edge of the rectangle
`ymin` :
    Upper left edge of the rectangle
`ymax` :
    Upper right edge of the rectangle

"""
function drawrect(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_drawrect),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

"""
    fillrect(xmin::Real, xmax::Real, ymin::Real, ymax::Real)

Draw a filled rectangle using the current fill attributes.

**Parameters:**

`xmin` :
    Lower left edge of the rectangle
`xmax` :
    Lower right edge of the rectangle
`ymin` :
    Upper left edge of the rectangle
`ymax` :
    Upper right edge of the rectangle

"""
function fillrect(xmin::Real, xmax::Real, ymin::Real, ymax::Real)
  ccall( libGR_ptr(:gr_fillrect),
        Nothing,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

"""
    drawarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Real, a2::Real)

Draw a circular or elliptical arc covering the specified rectangle.

**Parameters:**

`xmin` :
    Lower left edge of the rectangle
`xmax` :
    Lower right edge of the rectangle
`ymin` :
    Upper left edge of the rectangle
`ymax` :
    Upper right edge of the rectangle
`a1` :
    The start angle
`a2` :
    The end angle

The resulting arc begins at `a1` and ends at `a2` degrees. Angles are interpreted
such that 0 degrees is at the 3 o'clock position. The center of the arc is the center
of the given rectangle.

"""
function drawarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Real, a2::Real)
  ccall( libGR_ptr(:gr_drawarc),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax, a1, a2)
end

"""
    fillarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Real, a2::Real)

Fill a circular or elliptical arc covering the specified rectangle.

**Parameters:**

`xmin` :
    Lower left edge of the rectangle
`xmax` :
    Lower right edge of the rectangle
`ymin` :
    Upper left edge of the rectangle
`ymax` :
    Upper right edge of the rectangle
`a1` :
    The start angle
`a2` :
    The end angle

The resulting arc begins at `a1` and ends at `a2` degrees. Angles are interpreted
such that 0 degrees is at the 3 o'clock position. The center of the arc is the center
of the given rectangle.

"""
function fillarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Real, a2::Real)
  ccall( libGR_ptr(:gr_fillarc),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax, a1, a2)
end

"""
    drawpath(points, codes, fill::Int)

Draw simple and compound outlines consisting of line segments and bezier curves.

**Parameters:**

`points` :
    (N, 2) array of (x, y) vertices
`codes` :
    N-length array of path codes
`fill` :
    A flag indication whether resulting path is to be filled or not

The following path codes are recognized:

    +----------+-----------------------------------------------------------+
    |      STOP|end the entire path                                        |
    +----------+-----------------------------------------------------------+
    |    MOVETO|move to the given vertex                                   |
    +----------+-----------------------------------------------------------+
    |    LINETO|draw a line from the current position to the given vertex  |
    +----------+-----------------------------------------------------------+
    |    CURVE3|draw a quadratic Bézier curve                              |
    +----------+-----------------------------------------------------------+
    |    CURVE4|draw a cubic Bézier curve                                  |
    +----------+-----------------------------------------------------------+
    | CLOSEPOLY|draw a line segment to the start point of the current path |
    +----------+-----------------------------------------------------------+

"""
function drawpath(points, codes, fill::Int)
  len = length(codes)
  ccall( libGR_ptr(:gr_drawpath),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{UInt8}, Int32),
        len, convert(Vector{Float64}, points), convert(Vector{UInt8}, codes), fill)
end

"""
    setarrowstyle(style::Int)

Set the arrow style to be used for subsequent arrow commands.

**Parameters:**

`style` :
    The arrow style to be used

`setarrowstyle` defines the arrow style for subsequent arrow primitives.
The default arrow style is 1.

    +---+----------------------------------+
    |  1|simple, single-ended              |
    +---+----------------------------------+
    |  2|simple, single-ended, acute head  |
    +---+----------------------------------+
    |  3|hollow, single-ended              |
    +---+----------------------------------+
    |  4|filled, single-ended              |
    +---+----------------------------------+
    |  5|triangle, single-ended            |
    +---+----------------------------------+
    |  6|filled triangle, single-ended     |
    +---+----------------------------------+
    |  7|kite, single-ended                |
    +---+----------------------------------+
    |  8|filled kite, single-ended         |
    +---+----------------------------------+
    |  9|simple, double-ended              |
    +---+----------------------------------+
    | 10|simple, double-ended, acute head  |
    +---+----------------------------------+
    | 11|hollow, double-ended              |
    +---+----------------------------------+
    | 12|filled, double-ended              |
    +---+----------------------------------+
    | 13|triangle, double-ended            |
    +---+----------------------------------+
    | 14|filled triangle, double-ended     |
    +---+----------------------------------+
    | 15|kite, double-ended                |
    +---+----------------------------------+
    | 16|filled kite, double-ended         |
    +---+----------------------------------+
    | 17|double line, single-ended         |
    +---+----------------------------------+
    | 18|double line, double-ended         |
    +---+----------------------------------+

"""
function setarrowstyle(style::Int)
  ccall( libGR_ptr(:gr_setarrowstyle),
        Nothing,
        (Int32, ),
        style)
end

"""
    setarrowsize(size::Real)

Set the arrow size to be used for subsequent arrow commands.

**Parameters:**

`size` :
    The arrow size to be used

`setarrowsize` defines the arrow size for subsequent arrow primitives.
The default arrow size is 1.

"""
function setarrowsize(size::Real)
  ccall( libGR_ptr(:gr_setarrowsize),
        Nothing,
        (Float64, ),
        size)
end

"""
    drawarrow(x1::Real, y1::Real, x2::Real, y2::Real)

Draw an arrow between two points.

**Parameters:**

`x1`, `y1` :
    Starting point of the arrow (tail)
`x2`, `y2` :
    Head of the arrow

Different arrow styles (angles between arrow tail and wing, optionally filled
heads, double headed arrows) are available and can be set with the `setarrowstyle`
function.

"""
function drawarrow(x1::Real, y1::Real, x2::Real, y2::Real)
  ccall( libGR_ptr(:gr_drawarrow),
        Nothing,
        (Float64, Float64, Float64, Float64),
        x1, y1, x2, y2)
end

function readimage(path)
  width = Cint[0]
  height = Cint[0]
  data = Array{Ptr{UInt32}}(undef, 1)
  ret = ccall( libGR_ptr(:gr_readimage),
              Int32,
              (Ptr{Cchar}, Ptr{Int32}, Ptr{Int32}, Ptr{Ptr{UInt32}}),
              path, width, height, data)
  if width[1] > 0 && height[1] > 0
    img = unsafe_wrap(Array{UInt32}, data[1], (width[1], height[1]))
    return Int(width[1]), Int(height[1]), img
  else
    return 0, 0, zeros(UInt32, 0)
  end
end

"""
    drawimage(xmin::Real, xmax::Real, ymin::Real, ymax::Real, width::Int, height::Int, data, model::Int = 0)

Draw an image into a given rectangular area.

**Parameters:**

`xmin`, `ymin` :
    First corner point of the rectangle
`xmax`, `ymax` :
    Second corner point of the rectangle
`width`, `height` :
    The width and the height of the image
`data` :
    An array of color values dimensioned `width` by `height`
`model` :
    Color model (default=0)

The available color models are:

    +-----------------------+---+-----------+
    |MODEL_RGB              |  0|   AABBGGRR|
    +-----------------------+---+-----------+
    |MODEL_HSV              |  1|   AAVVSSHH|
    +-----------------------+---+-----------+


The points (`xminx`, `ymin`) and (`xmax`, `ymax`) are world coordinates defining
diagonally opposite corner points of a rectangle. This rectangle is divided into
`width` by `height` cells. The two-dimensional array `data` specifies colors
for each cell.

"""
function drawimage(xmin::Real, xmax::Real, ymin::Real, ymax::Real, width::Int, height::Int, data, model::Int = 0)
  if ndims(data) == 2
    data = reshape(data, width * height)
  end
  ccall( libGR_ptr(:gr_drawimage),
        Nothing,
        (Float64, Float64, Float64, Float64, Int32, Int32, Ptr{UInt32}, Int32),
        xmin, xmax, ymin, ymax, width, height, convert(Vector{UInt32}, data), model)
end

function importgraphics(path)
  return ccall( libGR_ptr(:gr_importgraphics),
               Int32,
               (Ptr{Cchar}, ),
               path)
end

"""
    setshadow(offsetx::Real, offsety::Real, blur::Real)

`setshadow` allows drawing of shadows, realized by images painted underneath,
and offset from, graphics objects such that the shadow mimics the effect of a light
source cast on the graphics objects.

**Parameters:**

`offsetx` :
    An x-offset, which specifies how far in the horizontal direction the
    shadow is offset from the object
`offsety` :
    A y-offset, which specifies how far in the vertical direction the shadow
    is offset from the object
`blur` :
    A blur value, which specifies whether the object has a hard or a diffuse
    edge

"""
function setshadow(offsetx::Real, offsety::Real, blur::Real)
  ccall( libGR_ptr(:gr_setshadow),
        Nothing,
        (Float64, Float64, Float64),
        offsetx, offsety, blur)
end

"""
    settransparency(alpha::Real)

Set the value of the alpha component associated with GR colors.

**Parameters:**

`alpha` :
    An alpha value (0.0 - 1.0)

"""
function settransparency(alpha::Real)
  ccall( libGR_ptr(:gr_settransparency),
        Nothing,
        (Float64, ),
        alpha)
end

"""
    setcoordxform(mat)

Change the coordinate transformation according to the given matrix.

**Parameters:**

`mat[3][2]` :
    2D transformation matrix

"""
function setcoordxform(mat)
  @assert length(mat) == 6
  ccall( libGR_ptr(:gr_setcoordxform),
        Nothing,
        (Ptr{Float64}, ),
        convert(Vector{Float64}, mat))
end

"""
    begingraphics(path)

Open a file for graphics output.

**Parameters:**

`path` :
    Filename for the graphics file.

`begingraphics` allows to write all graphics output into a XML-formatted file until
the `endgraphics` functions is called. The resulting file may later be imported with
the `importgraphics` function.

"""
function begingraphics(path)
  ccall( libGR_ptr(:gr_begingraphics),
        Nothing,
        (Ptr{Cchar}, ),
        path)
end

function endgraphics()
  ccall( libGR_ptr(:gr_endgraphics),
        Nothing,
        ()
        )
end

function getgraphics()
  string = ccall( libGR_ptr(:gr_getgraphics),
                 Ptr{Cchar},
                 (),
                 )
  return string != C_NULL ? unsafe_string(string) : ""
end

function drawgraphics(string)
  ret = ccall( libGR_ptr(:gr_drawgraphics),
              Int32,
              (Ptr{Cchar}, ),
              string)
  return Int(ret)
end

function startlistener()
  ret = ccall( libGR_ptr(:gr_startlistener),
              Int32,
              (),
              )
  return Int(ret)
end

"""
    mathtex(x::Real, y::Real, string)

Generate a character string starting at the given location. Strings can be defined
to create mathematical symbols and Greek letters using LaTeX syntax.

**Parameters:**

`x`, `y` :
    Position of the text string specified in world coordinates
`string` :
    The text string to be drawn

"""
function mathtex(x::Real, y::Real, string)
  if length(string) >= 2 && string[1] == '$' && string[end] == '$'
    string = string[2:end-1]
  end
  ccall( libGR_ptr(:gr_mathtex),
        Nothing,
        (Float64, Float64, Ptr{Cchar}),
        x, y, string)
end

function inqmathtex(x, y, string)
  if length(string) >= 2 && string[1] == '$' && string[end] == '$'
    string = string[2:end-1]
  end
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( libGR_ptr(:gr_inqmathtex),
        Nothing,
        (Float64, Float64, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, string, tbx, tby)
  return tbx, tby
end

const ASF_BUNDLED = 0
const ASF_INDIVIDUAL = 1

const NOCLIP = 0
const CLIP = 1

const COORDINATES_WC = 0
const COORDINATES_NDC = 1

const INTSTYLE_HOLLOW = 0
const INTSTYLE_SOLID = 1
const INTSTYLE_PATTERN = 2
const INTSTYLE_HATCH = 3

const TEXT_HALIGN_NORMAL = 0
const TEXT_HALIGN_LEFT = 1
const TEXT_HALIGN_CENTER = 2
const TEXT_HALIGN_RIGHT = 3
const TEXT_VALIGN_NORMAL = 0
const TEXT_VALIGN_TOP = 1
const TEXT_VALIGN_CAP = 2
const TEXT_VALIGN_HALF = 3
const TEXT_VALIGN_BASE = 4
const TEXT_VALIGN_BOTTOM = 5

const TEXT_PATH_RIGHT = 0
const TEXT_PATH_LEFT = 1
const TEXT_PATH_UP = 2
const TEXT_PATH_DOWN = 3

const TEXT_PRECISION_STRING = 0
const TEXT_PRECISION_CHAR = 1
const TEXT_PRECISION_STROKE = 2
const TEXT_PRECISION_OUTLINE = 3

const LINETYPE_SOLID = 1
const LINETYPE_DASHED = 2
const LINETYPE_DOTTED = 3
const LINETYPE_DASHED_DOTTED = 4
const LINETYPE_DASH_2_DOT = -1
const LINETYPE_DASH_3_DOT = -2
const LINETYPE_LONG_DASH = -3
const LINETYPE_LONG_SHORT_DASH = -4
const LINETYPE_SPACED_DASH = -5
const LINETYPE_SPACED_DOT = -6
const LINETYPE_DOUBLE_DOT = -7
const LINETYPE_TRIPLE_DOT = -8

const MARKERTYPE_DOT = 1
const MARKERTYPE_PLUS = 2
const MARKERTYPE_ASTERISK = 3
const MARKERTYPE_CIRCLE = 4
const MARKERTYPE_DIAGONAL_CROSS = 5
const MARKERTYPE_SOLID_CIRCLE = -1
const MARKERTYPE_TRIANGLE_UP = -2
const MARKERTYPE_SOLID_TRI_UP = -3
const MARKERTYPE_TRIANGLE_DOWN = -4
const MARKERTYPE_SOLID_TRI_DOWN = -5
const MARKERTYPE_SQUARE = -6
const MARKERTYPE_SOLID_SQUARE = -7
const MARKERTYPE_BOWTIE = -8
const MARKERTYPE_SOLID_BOWTIE = -9
const MARKERTYPE_HOURGLASS = -10
const MARKERTYPE_SOLID_HGLASS = -11
const MARKERTYPE_DIAMOND = -12
const MARKERTYPE_SOLID_DIAMOND = -13
const MARKERTYPE_STAR = -14
const MARKERTYPE_SOLID_STAR = -15
const MARKERTYPE_TRI_UP_DOWN = -16
const MARKERTYPE_SOLID_TRI_RIGHT = -17
const MARKERTYPE_SOLID_TRI_LEFT = -18
const MARKERTYPE_HOLLOW_PLUS = -19
const MARKERTYPE_SOLID_PLUS = -20
const MARKERTYPE_PENTAGON = -21
const MARKERTYPE_HEXAGON = -22
const MARKERTYPE_HEPTAGON = -23
const MARKERTYPE_OCTAGON = -24
const MARKERTYPE_STAR_4 = -25
const MARKERTYPE_STAR_5 = -26
const MARKERTYPE_STAR_6 = -27
const MARKERTYPE_STAR_7 = -28
const MARKERTYPE_STAR_8 = -29
const MARKERTYPE_VLINE = -30
const MARKERTYPE_HLINE = -31
const MARKERTYPE_OMARK = -32

const OPTION_X_LOG = 1
const OPTION_Y_LOG = 2
const OPTION_Z_LOG = 4
const OPTION_FLIP_X = 8
const OPTION_FLIP_Y = 16
const OPTION_FLIP_Z = 32
const OPTION_X_LOG2 = 64
const OPTION_Y_LOG2 = 128
const OPTION_Z_LOG2 = 256
const OPTION_X_LN = 512
const OPTION_Y_LN = 1024
const OPTION_Z_LN = 2048

const OPTION_LINES = 0
const OPTION_MESH = 1
const OPTION_FILLED_MESH = 2
const OPTION_Z_SHADED_MESH = 3
const OPTION_COLORED_MESH = 4
const OPTION_CELL_ARRAY = 5
const OPTION_SHADED_MESH = 6
const OPTION_3D_MESH = 7

const MODEL_RGB = 0
const MODEL_HSV = 1

const COLORMAP_UNIFORM = 0
const COLORMAP_TEMPERATURE = 1
const COLORMAP_GRAYSCALE = 2
const COLORMAP_GLOWING = 3
const COLORMAP_RAINBOWLIKE = 4
const COLORMAP_GEOLOGIC = 5
const COLORMAP_GREENSCALE = 6
const COLORMAP_CYANSCALE = 7
const COLORMAP_BLUESCALE = 8
const COLORMAP_MAGENTASCALE = 9
const COLORMAP_REDSCALE = 10
const COLORMAP_FLAME = 11
const COLORMAP_BROWNSCALE = 12
const COLORMAP_PILATUS = 13
const COLORMAP_AUTUMN = 14
const COLORMAP_BONE = 15
const COLORMAP_COOL = 16
const COLORMAP_COPPER = 17
const COLORMAP_GRAY = 18
const COLORMAP_HOT = 19
const COLORMAP_HSV = 20
const COLORMAP_JET = 21
const COLORMAP_PINK = 22
const COLORMAP_SPECTRAL = 23
const COLORMAP_SPRING = 24
const COLORMAP_SUMMER = 25
const COLORMAP_WINTER = 26
const COLORMAP_GIST_EARTH = 27
const COLORMAP_GIST_HEAT = 28
const COLORMAP_GIST_NCAR = 29
const COLORMAP_GIST_RAINBOW = 30
const COLORMAP_GIST_STERN = 31
const COLORMAP_AFMHOT = 32
const COLORMAP_BRG = 33
const COLORMAP_BWR = 34
const COLORMAP_COOLWARM = 35
const COLORMAP_CMRMAP = 36
const COLORMAP_CUBEHELIX = 37
const COLORMAP_GNUPLOT = 38
const COLORMAP_GNUPLOT2 = 39
const COLORMAP_OCEAN = 40
const COLORMAP_RAINBOW = 41
const COLORMAP_SEISMIC = 42
const COLORMAP_TERRAIN = 43
const COLORMAP_VIRIDIS = 44
const COLORMAP_INFERNO = 45
const COLORMAP_PLASMA = 46
const COLORMAP_MAGMA = 47

const FONT_TIMES_ROMAN = 101
const FONT_TIMES_ITALIC = 102
const FONT_TIMES_BOLD = 103
const FONT_TIMES_BOLDITALIC = 104
const FONT_HELVETICA = 105
const FONT_HELVETICA_OBLIQUE = 106
const FONT_HELVETICA_BOLD = 107
const FONT_HELVETICA_BOLDOBLIQUE = 108
const FONT_COURIER = 109
const FONT_COURIER_OBLIQUE = 110
const FONT_COURIER_BOLD = 111
const FONT_COURIER_BOLDOBLIQUE = 112
const FONT_SYMBOL = 113
const FONT_BOOKMAN_LIGHT = 114
const FONT_BOOKMAN_LIGHTITALIC = 115
const FONT_BOOKMAN_DEMI = 116
const FONT_BOOKMAN_DEMIITALIC = 117
const FONT_NEWCENTURYSCHLBK_ROMAN = 118
const FONT_NEWCENTURYSCHLBK_ITALIC = 119
const FONT_NEWCENTURYSCHLBK_BOLD = 120
const FONT_NEWCENTURYSCHLBK_BOLDITALIC = 121
const FONT_AVANTGARDE_BOOK = 122
const FONT_AVANTGARDE_BOOKOBLIQUE = 123
const FONT_AVANTGARDE_DEMI = 124
const FONT_AVANTGARDE_DEMIOBLIQUE = 125
const FONT_PALATINO_ROMAN = 126
const FONT_PALATINO_ITALIC = 127
const FONT_PALATINO_BOLD = 128
const FONT_PALATINO_BOLDITALIC = 129
const FONT_ZAPFCHANCERY_MEDIUMITALIC = 130
const FONT_ZAPFDINGBATS = 131

const TEXT_USE_WC = 1
const TEXT_ENABLE_INLINE_MATH = 2

const PATH_STOP      = 0x00
const PATH_MOVETO    = 0x01
const PATH_LINETO    = 0x02
const PATH_CURVE3    = 0x03
const PATH_CURVE4    = 0x04
const PATH_CLOSEPOLY = 0x4f

const GDP_DRAW_PATH = 1
const GDP_DRAW_LINES = 2
const GDP_DRAW_MARKERS = 3

const MPL_SUPPRESS_CLEAR = 1
const MPL_POSTPONE_UPDATE = 2

const XFORM_BOOLEAN = 0
const XFORM_LINEAR = 1
const XFORM_LOG = 2
const XFORM_LOGLOG = 3
const XFORM_CUBIC = 4
const XFORM_EQUALIZED = 5

# GR3 functions
include("gr3.jl")

const gr3 = GR.GR3

# Convenience functions
include("jlgr.jl")
# Rather than redefining the methods in GR
# 1. Export them in jlgr
# 2. Import them here via using
using .jlgr

mutable struct SVG s::Array{UInt8} end
mutable struct PNG s::Array{UInt8} end
mutable struct HTML s::AbstractString end

Base.show(io::IO, ::MIME"image/svg+xml", x::SVG) = write(io, x.s)
Base.show(io::IO, ::MIME"image/png", x::PNG) = write(io, x.s)
Base.show(io::IO, ::MIME"text/html", x::HTML) = print(io, x.s)

function _readfile(path)
    data = Array{UInt8}(undef, filesize(path))
    s = open(path, "r")
    content = read!(s, data)
    close(s)
    content
end

function isinline()
    return !(mime_type[] in ("", "mov", "mp4", "webm"))
end

function displayname()
    return display_name[]
end

function inline(mime="svg", scroll=true)
    init()
    if mime_type[] != mime
        @debug "MIME type change" mime_type[] mime
        if mime == "iterm"
            file_path[] = tempname() * ".png"
            ENV["GKS_WSTYPE"] = "png"
            usecolorscheme(is_dark_mode() ? 2 : 1)
        elseif mime == "mlterm"
            file_path[] = tempname() * ".six"
            ENV["GKS_WSTYPE"] = "six"
        elseif mime == "js"
            file_path[] = nothing
            ENV["GRDISPLAY"] = "js"
            send_c[], recv_c[] = js.initjs()
        else
            file_path[] = tempname() * "." * mime
            ENV["GKS_WSTYPE"] = mime
        end
        if file_path[] !== nothing
            ENV["GKS_FILEPATH"] = file_path[]
        end
        @debug mime file_path[] ENV["GKS_WSTYPE"]
        emergencyclosegks()
        mime_type[] = mime
    end
    figure_count[] = scroll ? -1 : 0
    @debug mime_type[]
    mime_type[]
end

function reset()
    mime_type[] = ""
    file_path[] = ""
    figure_count[] = -1
    delete!(ENV, "GKS_WSTYPE")
    delete!(ENV, "GKS_FILEPATH")
    emergencyclosegks()
end

function show()
    if !isempty(mime_type[])
        emergencyclosegks()
    end
    if mime_type[] == "svg"
        content = SVG(_readfile(file_path[]))
        rm(file_path[])
        return content
    elseif mime_type[] == "png"
        content = PNG(_readfile(file_path[]))
        rm(file_path[])
        return content
    elseif mime_type[] in ("mov", "mp4", "webm")
        mimespec = mime_type[] == "mov" ? "video/mp4" : "video/$(mime_type[])"
        content = HTML(string("""<video autoplay controls><source type="$mimespec" src="data:$mimespec;base64,""", Base64.base64encode(open(read,file_path[])),""""></video>"""))
        rm(file_path[])
        return content
    elseif mime_type[] == "iterm"
        content = string(osc_seq(), "1337;File=inline=1;height=24;preserveAspectRatio=0:", Base64.base64encode(open(read,file_path[])), st_seq())
        if figure_count[] != -1
            figure_count[] += 1
            (figure_count[] > 1) && print("\e[24A")
        end
        println(content)
        rm(file_path[])
        return nothing
    elseif mime_type[] == "mlterm"
        content = read(file_path[], String)
        println(content)
        rm(file_path[])
        return nothing
    end
    return nothing
end

function setregenflags(flags=0)
  ccall( libGR_ptr(:gr_setregenflags),
        Nothing,
        (Int32, ),
        flags)
end

function inqregenflags()
  flags = ccall( libGR_ptr(:gr_inqregenflags),
                Int32,
                ()
                )
  return flags
end

function savestate()
  ccall( libGR_ptr(:gr_savestate),
        Nothing,
        ()
        )
end

function restorestate()
  ccall( libGR_ptr(:gr_restorestate),
        Nothing,
        ()
        )
end

function selectcontext(context::Int)
  ccall( libGR_ptr(:gr_selectcontext),
        Nothing,
        (Int32, ),
        context)
end

function destroycontext(context::Int)
  ccall( libGR_ptr(:gr_destroycontext),
        Nothing,
        (Int32, ),
        context)
end

function uselinespec(linespec)
  return ccall( libGR_ptr(:gr_uselinespec),
               Int32,
               (Ptr{Cchar}, ),
               linespec)
end

function delaunay(x, y)
  @assert length(x) == length(y)
  npoints = length(x)
  ntri = Cint[0]
  dim = Cint[3]
  triangles = Array{Ptr{Int32}}(undef, 1)
  ccall( libGR_ptr(:gr_delaunay),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Ptr{Int32}}),
        npoints, convert(Vector{Float64}, x), convert(Vector{Float64}, y),
        ntri, triangles)
  if ntri[1] > 0
    tri = unsafe_wrap(Array{Int32}, triangles[1], (dim[1], ntri[1]))
    return Int(ntri[1]), tri' .+ 1
  else
    return 0, zeros(Int32, 0)
  end
end

function interp2(X, Y, Z, Xq, Yq, method::Int=0, extrapval=0)
  nx = length(X)
  ny = length(Y)
  if isa(Z, Function)
    f = Z
    Z = Float64[f(x,y) for x in X, y in Y]
  end
  nz = length(Z)
  if ndims(Z) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(Z) == 2
    out_of_bounds = size(Z)[1] != ny || size(Z)[2] != nx
  else
    out_of_bounds = true
  end
  Zq = []
  if !out_of_bounds
    if ndims(Z) == 2
      Z = reshape(Z, nx * ny)
    end
    nxq = length(Xq)
    nyq = length(Yq)
    Zq = Cdouble[1 : nxq * nyq; ]
    ccall( libGR_ptr(:gr_interp2),
          Nothing,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Cdouble}, Int32, Float64),
          ny, nx, convert(Vector{Float64}, Y), convert(Vector{Float64}, X), convert(Vector{Float64}, Z), nyq, nxq, convert(Vector{Float64}, Yq), convert(Vector{Float64}, Xq), Zq, method, extrapval)
    reshape(Zq, nyq, nxq)
  else
    error("Arrays have incorrect length or dimension.")
    Z
  end
end

"""
    trisurface(x, y, z)

Draw a triangular surface plot for the given data points.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`z` :
    A list containing the Z coordinates

"""
function trisurface(x, y, z)
  nx = length(x)
  ny = length(y)
  nz = length(z)
  n = min(nx, ny, nz)
  ccall( libGR_ptr(:gr_trisurface),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), convert(Vector{Float64}, z))
end

"""
    tricontour(x, y, z, levels)

Draw a contour plot for the given triangle mesh.

**Parameters:**

`x` :
    A list containing the X coordinates
`y` :
    A list containing the Y coordinates
`z` :
    A list containing the Z coordinates
`levels` :
    A list containing the contour levels

"""
function tricontour(x, y, z, levels)
  npoints = length(x)
  nlevels = length(levels)
  ccall( libGR_ptr(:gr_tricontour),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32, Ptr{Float64}),
        npoints, convert(Vector{Float64}, x), convert(Vector{Float64}, y), convert(Vector{Float64}, z), nlevels, convert(Vector{Float64}, levels))
end

function gradient(x, y, z)
  nx = length(x)
  ny = length(y)
  nz = length(z)
  if ndims(z) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(z) == 2
    out_of_bounds = size(z)[1] != nx || size(z)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if ndims(z) == 2
      z = reshape(z, nx * ny)
    end
    u = Cdouble[1 : nx*ny ;]
    v = Cdouble[1 : nx*ny ;]
    ccall( libGR_ptr(:gr_gradient),
          Nothing,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Cdouble}, Ptr{Cdouble}),
          nx, ny, convert(Vector{Float64}, x), convert(Vector{Float64}, y), convert(Vector{Float64}, z), u, v)
    return u, v
  else
    return [], []
  end
end

function quiver(x, y, u, v, color::Bool=false)
  nx = length(x)
  ny = length(y)
  nu = length(u)
  nv = length(v)
  if ndims(u) == 1
    out_of_bounds = nu != nx * ny
  elseif ndims(u) == 2
    out_of_bounds = size(u)[1] != nx || size(u)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if ndims(v) == 1
      out_of_bounds = nv != nx * ny
    elseif ndims(v) == 2
      out_of_bounds = size(v)[1] != nx || size(v)[2] != ny
    else
      out_of_bounds = true
    end
  end
  if !out_of_bounds
    if ndims(u) == 2
      u = reshape(u, nx * ny)
    end
    if ndims(v) == 2
      v = reshape(v, nx * ny)
    end
    ccall( libGR_ptr(:gr_quiver),
          Nothing,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, convert(Vector{Float64}, x), convert(Vector{Float64}, y), convert(Vector{Float64}, u), convert(Vector{Float64}, v), convert(Int32, color))
  else
    error("Arrays have incorrect length or dimension.")
  end
end

function reducepoints(xd, yd, n)
  @assert length(xd) == length(yd)
  nd = length(xd)
  x = Cdouble[1 : n ;]
  y = Cdouble[1 : n ;]
  ccall( libGR_ptr(:gr_reducepoints),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Ptr{Cdouble}, Ptr{Cdouble}),
        nd, convert(Vector{Float64}, xd), convert(Vector{Float64}, yd), n, x, y)
  return x, y
end

function version()
  info = ccall( libGR_ptr(:gr_version),
               Cstring,
               ()
               )
  unsafe_string(info)
end

function check_for_updates()
    @eval GR begin
        import HTTP
        requ = HTTP.request("GET", "https://api.github.com/repos/sciapp/gr/releases/latest")
        body = String(requ.body)

        import JSON
        tag = JSON.parse(body)["tag_name"]
    end

    release = replace(string("v", version()), ".post" => " patchlevel ")
    if release < tag
        println("An update is available: GR $tag. You're using GR $release.")
    elseif release == tag
        println("You're up-to-date. GR $tag is currently the newest version available.")
    else
        println("You're using a pre-release version: GR $release.")
    end
    release < tag
end

function openmeta(target=0, device="localhost", port=8002)
    handle = ccall(libGRM_ptr(:grm_open),
                   Ptr{Nothing},
                   (Int32, Cstring, Int64, Ptr{Cvoid}, Ptr{Cvoid}),
                   target, device, port, send_c[], recv_c[])
    return handle
end

function sendmeta(handle, string::AbstractString)
    ccall(libGRM_ptr(:grm_send),
          Nothing,
          (Ptr{Nothing}, Cstring),
          handle, string)
end

function sendmetaref(handle, key::AbstractString, fmt::Char, data, len=-1)
    if typeof(data) <: String
        if len == -1
            len = length(data)
        end
        ccall(libGRM_ptr(:grm_send_ref),
              Nothing,
              (Ptr{Nothing}, Cstring, Cchar, Cstring, Int32),
              handle, key, fmt, data, len)
    else
        if len == -1
            len = length(data)
        end
        if typeof(data) <: Array
            if typeof(data[1]) <: String
                ccall(libGRM_ptr(:grm_send_ref),
                      Nothing,
                      (Ptr{Nothing}, Cstring, Cchar, Ptr{Ptr{Cchar}}, Int32),
                      handle, key, fmt, data, len)
                return
            else
                ref = Ref(data, 1)
            end
        else
            ref = Ref(data)
        end
        ccall(libGRM_ptr(:grm_send_ref),
              Nothing,
              (Ptr{Nothing}, Cstring, Cchar, Ptr{Nothing}, Int32),
              handle, key, fmt, ref, len)
    end
end

function recvmeta(handle, args=C_NULL)
    args = ccall(libGRM_ptr(:grm_recv),
                 Ptr{Nothing},
                 (Ptr{Nothing}, Ptr{Nothing}),
                 handle, args)
    return args
end

function plotmeta(args)
    ccall(libGRM_ptr(:grm_plot),
          Nothing,
          (Ptr{Nothing}, ),
          args)
end

function deletemeta(args)
    ccall(libGRM_ptr(:grm_args_delete),
          Nothing,
          (Ptr{Nothing}, ),
          args)
end

function closemeta(handle)
    ccall(libGRM_ptr(:grm_close),
          Nothing,
          (Ptr{Nothing}, ),
          handle)
end

function shadepoints(x, y; dims=[1200, 1200], xform=1)
    @assert length(x) == length(y)
    n = length(x)
    w, h = dims
    ccall( libGR_ptr(:gr_shadepoints),
          Nothing,
          (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Int32),
          n, convert(Vector{Float64}, x), convert(Vector{Float64}, y),
          xform, w, h)
end

function shadelines(x, y; dims=[1200, 1200], xform=1)
    @assert length(x) == length(y)
    n = length(x)
    w, h = dims
    ccall( libGR_ptr(:gr_shadelines),
          Nothing,
          (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Int32),
          n, convert(Vector{Float64}, x), convert(Vector{Float64}, y),
          xform, w, h)
end

function setcolormapfromrgb(r, g, b; positions=Nothing)
    @assert length(r) == length(g) == length(b)
    n = length(r)
    if positions === Nothing
        positions = C_NULL
    else
        @assert length(positions) == n
        positions = convert(Vector{Float64}, positions)
    end
    ccall( libGR_ptr(:gr_setcolormapfromrgb),
          Nothing,
          (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
          n, convert(Vector{Float64}, r), convert(Vector{Float64}, g),
          convert(Vector{Float64}, b), positions)
end

function panzoom(x, y, zoom)
  xmin = Cdouble[0]
  xmax = Cdouble[0]
  ymin = Cdouble[0]
  ymax = Cdouble[0]
  ccall( libGR_ptr(:gr_panzoom),
        Nothing,
        (Float64, Float64, Float64, Float64, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        x, y, zoom, zoom, xmin, xmax, ymin, ymax)
  return xmin[1], xmax[1], ymin[1], ymax[1]
end

"""
    setborderwidth(width::Real)

Define the border width of subsequent path output primitives.

**Parameters:**

`width` :
    The border width scale factor

"""
function setborderwidth(width::Real)
  ccall( libGR_ptr(:gr_setborderwidth),
        Nothing,
        (Float64, ),
        width)
end

"""
    setbordercolorind(color::Int)

Define the color of subsequent path output primitives.

**Parameters:**

`color` :
    The border color index (COLOR < 1256)

"""
function setbordercolorind(color::Int)
  ccall( libGR_ptr(:gr_setbordercolorind),
        Nothing,
        (Int32, ),
        color)
end

function setprojectiontype(type::Int)
  ccall( libGR_ptr(:gr_setprojectiontype),
        Nothing,
        (Int32, ),
        type)
end

function setperspectiveprojection(near_plane::Real, far_plane::Real, fov::Real)
  ccall( libGR_ptr(:gr_setperspectiveprojection),
        Nothing,
        (Float64, Float64, Float64),
        near_plane, far_plane, fov)
end

function setorthographicprojection(left::Real, right::Real, bottom::Real, top::Real, near_plane::Real, far_plane::Real)
  ccall( libGR_ptr(:gr_setorthographicprojection),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64),
        left, right, bottom, top, near_plane, far_plane)
end

function settransformationparameters(camera_pos_x::Real, camera_pos_y::Real, camera_pos_z::Real,
                                     up_x::Real, up_y::Real, up_z::Real,
                                     focus_point_x::Real, focus_point_y::Real, focus_point_z::Real)
  ccall( libGR_ptr(:gr_settransformationparameters),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64),
        camera_pos_x, camera_pos_y, camera_pos_z, up_x, up_y, up_z, focus_point_x, focus_point_y, focus_point_z)
end

function setresamplemethod(method::UInt32)
  ccall( libGR_ptr(:gr_setresamplemethod),
        Nothing,
        (UInt32, ),
        method)
end

function setwindow3d(xmin::Real, xmax::Real, ymin::Real, ymax::Real, zmin::Real, zmax::Real)
  ccall( libGR_ptr(:gr_setwindow3d),
        Nothing,
        (Float64, Float64, Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax, zmin, zmax)
end

function setspace3d(rot::Real, tilt::Real, fov::Real, dist::Real)
  ccall( libGR_ptr(:gr_setspace3d),
        Nothing,
        (Float64, Float64, Float64, Float64),
        rot, tilt, fov, dist)
end

function text3d(x::Real, y::Real, z::Real, string, axis::Int)
  ccall( libGR_ptr(:gr_text3d),
        Nothing,
        (Float64, Float64, Float64, Ptr{UInt8}, Int32),
        x, y, z, latin1(string), axis)
end

function inqtext3d(x::Real, y::Real, z::Real, string, axis::Int)
  tbx = Cdouble[0 for i in 1:16]
  tby = Cdouble[0 for i in 1:16]
  ccall( libGR_ptr(:gr_inqtext3d),
        Nothing,
        (Float64, Float64, Float64, Ptr{UInt8}, Int32, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, z, latin1(string), axis, tbx, tby)
  return tbx, tby
end

function settextencoding(encoding)
    ccall( libGR_ptr(:gr_settextencoding),
        Nothing,
        (Int32, ),
        encoding)
    text_encoding[] = encoding
end

function inqtextencoding()
  encoding = Cint[0]
  ccall( libGR_ptr(:gr_inqtextencoding),
        Nothing,
        (Ptr{Cint}, ),
        encoding)
  return encoding[1]
end

function loadfont(name::String)
  font = Cint[0]
  ccall( libGR_ptr(:gr_loadfont),
        Cstring,
        (Cstring, Ptr{Cint}),
        name, font)
  return Int(font[1])
end

function inqvpsize()
  width = Cint[0]
  height = Cint[0]
  device_pixel_ratio = Cdouble[0]
  ccall( libGR_ptr(:gr_inqvpsize),
        Nothing,
        (Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
        width, height, device_pixel_ratio)
  return width[1], height[1], device_pixel_ratio[1]
end

function setpicturesizeforvolume(width::Int, height::Int)
  ccall( libGR_ptr(:gr_setpicturesizeforvolume),
        Nothing,
        (Cint, Cint),
        width, height)
end

function inqtransformationparameters()
  cam_x = Cdouble[0]
  cam_y = Cdouble[0]
  cam_z = Cdouble[0]
  up_x = Cdouble[0]
  up_y = Cdouble[0]
  up_z = Cdouble[0]
  foc_x = Cdouble[0]
  foc_y = Cdouble[0]
  foc_z = Cdouble[0]
  ccall( libGR_ptr(:gr_inqtransformationparameters),
        Nothing,
        (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
        cam_x, cam_y, cam_z, up_x, up_y, up_z, foc_x, foc_y, foc_z)
  return cam_x[1], cam_y[1], cam_z[1], up_x[1], up_y[1], up_z[1], foc_x[1], foc_y[1], foc_z[1]
end

function polygonmesh3d(px, py, pz, connections, colors)
  @assert length(px) == length(py) == length(pz)
  num_points = length(px)
  num_connections = length(colors)
  ccall( libGR_ptr(:gr_polygonmesh3d),
        Nothing,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32, Ptr{Int32}, Ptr{Int32}),
        num_points, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz), num_connections, convert(Vector{Int32}, connections), convert(Vector{Int32}, colors))
end

function setscientificformat(format_option)
    ccall( libGR_ptr(:gr_setscientificformat),
        Nothing,
        (Int32, ),
        format_option)
end

function setresizebehaviour(flag)
    ccall( libGR_ptr(:gr_setresizebehaviour),
        Nothing,
        (Int32, ),
        flag)
end

function inqprojectiontype()
    proj = Cint[0]
    ccall( libGR_ptr(:gr_inqprojectiontype),
          Nothing,
          (Ptr{Cint}, ),
          proj)
    return Int(proj[1])
end

function beginselection(index, type)
    ccall( libGR_ptr(:gr_beginselection),
        Nothing,
        (Cint, Cint),
        index, type)
end

function endselection()
    ccall( libGR_ptr(:gr_endselection),
        Nothing,
        (),
        )
end

function moveselection(x, y)
    ccall( libGR_ptr(:gr_moveselection),
        Nothing,
        (Cdouble, Cdouble),
        x, y)
end

function setmathfont(font::Int)
  ccall( libGR_ptr(:gr_setmathfont),
        Nothing,
        (Int32, ),
        font)
end

function inqmathfont()
  _font = Cint[0]
  ccall( libGR_ptr(:gr_inqmathfont),
        Nothing,
        (Ptr{Cint}, ),
        _font)
  return _font[1]
end

function setclipregion(region::Int)
  ccall( libGR_ptr(:gr_setclipregion),
        Nothing,
        (Int32, ),
        region)
end

function inqclipregion()
  _region = Cint[0]
  ccall( libGR_ptr(:gr_inqclipregion),
        Nothing,
        (Ptr{Cint}, ),
        _region)
  return _region[1]
end

# JS functions
include("js.jl")

include("precompile.jl")
_precompile_()

end # module
