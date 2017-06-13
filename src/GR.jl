__precompile__()

module GR

if Sys.KERNEL == :NT
  const os = :Windows
else
  const os = Sys.KERNEL
end

const None = Union{}

export
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
  fillarea,
  cellarray,
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
  setviewport,
  selntran,
  setclip,
  setwswindow,
  setwsviewport,
  createseg,
  copyseg,
  redrawsegws,
  setsegtran,
  closeseg,
  emergencyclosegks,
  updategks,
  setspace,
  textext,
  inqtextext,
  axes,
  grid,
  grid3d,
  verrorbars,
  herrorbars,
  polyline3d,
  polymarker3d,
  axes3d,
  titles3d,
  surface,
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
  mathtex,
  selectcontext,
  destroycontext,
  delaunay,
  interp2,
  trisurface,
  tricontour,
# gradient, # deprecated, but still in Base
  quiver,
  # Convenience functions
  jlgr,
  colormap,
  figure,
  gcf,
  hold,
  usecolorscheme,
  subplot,
  plot,
  oplot,
  semilogx,
  semilogy,
  loglog,
  scatter,
  stem,
  histogram,
  contourf,
  heatmap,
  wireframe,
  plot3,
  scatter3,
  title,
  xlabel,
  ylabel,
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
  libGR3,
  gr3,
  isinline,
  inline,
  displayname,
  mainloop


mime_type = None
figure_count = None
msgs = None
have_clear_output = isinteractive() && isdefined(Main, :IJulia) &&
                    isdefined(Main.IJulia, :clear_output)
display_name = None


function __init__()
    global libGR, libGR3, display_name
    if "GRDIR" in keys(ENV)
        grdir = ENV["GRDIR"]
        if grdir == ""
            grdir = None
        end
    elseif isdir(joinpath(homedir(), "gr"), "fonts")
        grdir = joinpath(homedir(), "gr")
    else
        grdir = None
        for d in ("/opt", "/usr/local", "/usr")
            if isdir(joinpath(d, "gr", "fonts"))
                grdir = joinpath(d, "gr")
                break
            end
        end
    end
    if grdir == None
        grdir = joinpath(dirname(@__FILE__), "..", "deps", "gr")
    end
    ENV["GRDIR"] = grdir
    ENV["GKS_FONTPATH"] = grdir
    if contains(grdir, "site-packages")
        const libGR = joinpath(grdir, "libGR.so")
        ENV["GKS_FONTPATH"] = grdir
    elseif os != :Windows
        const libGR = joinpath(grdir, "lib", "libGR.so")
    else
        const libGR = joinpath(grdir, "libGR.dll")
    end
    if !isfile(libGR)
        println("Unable to load GR framework runtime environment")
        println("$(libGR): No such file")
        exit(-1)
    end
    const libGR3 = replace(libGR, "libGR", "libGR3")
    ENV["GKS_USE_CAIRO_PNG"] = "true"
    if "GRDISPLAY" in keys(ENV)
        display_name = ENV["GRDISPLAY"]
    end
end

function opengks()
  ccall( (:gr_opengks, libGR),
        Void,
        ()
        )
end

function closegks()
  ccall( (:gr_closegks, libGR),
        Void,
        ()
        )
end

function inqdspsize()
  mwidth = Cdouble[0]
  mheight = Cdouble[0]
  width = Cint[0]
  height = Cint[0]
  ccall( (:gr_inqdspsize, libGR),
        Void,
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
  ccall( (:gr_openws, libGR),
        Void,
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
  ccall( (:gr_closews, libGR),
        Void,
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
  ccall( (:gr_activatews, libGR),
        Void,
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
  ccall( (:gr_deactivatews, libGR),
        Void,
        (Int32, ),
        workstation_id)
end

function clearws()
  global msgs
  try
    if isinline() && have_clear_output
      IJulia.clear_output(true)
    end
  catch
    have_clear_output = false
  end
  if msgs != None
    begingraphics("")
  end
  ccall( (:gr_clearws, libGR),
        Void,
        ()
        )
end

function updatews()
  global msgs
  if msgs != None
    endgraphics()
  end
  ccall( (:gr_updatews, libGR),
        Void,
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
  assert(length(x) == length(y))
  n = length(x)
  ccall( (:gr_polyline, libGR),
        Void,
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
  assert(length(x) == length(y))
  n = length(x)
  ccall( (:gr_polymarker, libGR),
        Void,
        (Int32, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y))
end

function latin1(string)
  b = convert(Array{UInt8}, string)
  s = zeros(UInt8, length(string))
  len = 0
  mask = 0
  for c in b
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
  return s
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
  ccall( (:gr_text, libGR),
        Void,
        (Float64, Float64, Ptr{UInt8}),
        x, y, latin1(string))
end

function inqtext(x, y, string)
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( (:gr_inqtext, libGR),
        Void,
        (Float64, Float64, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, latin1(string), tbx, tby)
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
  assert(length(x) == length(y))
  n = length(x)
  ccall( (:gr_fillarea, libGR),
        Void,
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
  ccall( (:gr_cellarray, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32, Int32, Int32, Int32, Int32, Ptr{Int32}),
        xmin, xmax, ymin, ymax, dimx, dimy, 1, 1, dimx, dimy, convert(Vector{Int32}, color))
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
  assert(length(x) == length(y))
  n = length(x)
  ccall( (:gr_spline, libGR),
        Void,
        (Int32, Ptr{Float64}, Ptr{Float64}, Int32, Int32),
        n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), m, method)
end

function gridit(xd, yd, zd, nx, ny)
  assert(length(xd) == length(yd) == length(zd))
  nd = length(xd)
  x = Cdouble[1 : nx ;]
  y = Cdouble[1 : ny ;]
  z = Cdouble[1 : nx*ny ;]
  ccall( (:gr_gridit, libGR),
        Void,
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
  ccall( (:gr_setlinetype, libGR),
        Void,
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
  ccall( (:gr_setlinewidth, libGR),
        Void,
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
  ccall( (:gr_setlinecolorind, libGR),
        Void,
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
  ccall( (:gr_setmarkertype, libGR),
        Void,
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
  ccall( (:gr_setmarkersize, libGR),
        Void,
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
  ccall( (:gr_setmarkercolorind, libGR),
        Void,
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
  ccall( (:gr_settextfontprec, libGR),
        Void,
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
  ccall( (:gr_setcharexpan, libGR),
        Void,
        (Float64, ),
        factor)
end

function setcharspace(spacing::Real)
  ccall( (:gr_setcharspace, libGR),
        Void,
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
  ccall( (:gr_settextcolorind, libGR),
        Void,
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
  ccall( (:gr_setcharheight, libGR),
        Void,
        (Float64, ),
        height)
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
  ccall( (:gr_setcharup, libGR),
        Void,
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
  ccall( (:gr_settextpath, libGR),
        Void,
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
  ccall( (:gr_settextalign, libGR),
        Void,
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
  ccall( (:gr_setfillintstyle, libGR),
        Void,
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
  ccall( (:gr_setfillstyle, libGR),
        Void,
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
  ccall( (:gr_setfillcolorind, libGR),
        Void,
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
  ccall( (:gr_setcolorrep, libGR),
        Void,
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
  ccall( (:gr_setscale, libGR),
        Void,
        (Int32, ),
        options)
end

function inqscale()
  _options = Cint[0]
   ccall( (:gr_inqscale, libGR),
         Void,
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
  ccall( (:gr_setwindow, libGR),
        Void,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
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
  ccall( (:gr_setviewport, libGR),
        Void,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
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
  ccall( (:gr_selntran, libGR),
        Void,
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
  ccall( (:gr_setclip, libGR),
        Void,
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
  ccall( (:gr_setwswindow, libGR),
        Void,
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
  ccall( (:gr_setwsviewport, libGR),
        Void,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

function createseg(segment::Int)
  ccall( (:gr_createseg, libGR),
        Void,
        (Int32, ),
        segment)
end

function copyseg(segment::Int)
  ccall( (:gr_copyseg, libGR),
        Void,
        (Int32, ),
        segment)
end

function redrawsegws()
  ccall( (:gr_redrawsegws, libGR),
        Void,
        ()
        )
end

function setsegtran(segment::Int, fx::Real, fy::Real, transx::Real, transy::Real, phi::Real, scalex::Real, scaley::Real)
  ccall( (:gr_setsegtran, libGR),
        Void,
        (Int32, Float64, Float64, Float64, Float64, Float64, Float64, Float64),
        segment, fx, fy, transx, transy, phi, scalex, scaley)
end

function closeseg()
  ccall( (:gr_closeseg, libGR),
        Void,
        ()
        )
end

function emergencyclosegks()
  ccall( (:gr_emergencyclosegks, libGR),
        Void,
        ()
        )
end

function updategks()
  ccall( (:gr_updategks, libGR),
        Void,
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
  ccall( (:gr_setspace, libGR),
        Void,
        (Float64, Float64, Int32, Int32),
        zmin, zmax, rotation, tilt)
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
  ccall( (:gr_textext, libGR),
        Void,
        (Float64, Float64, Ptr{UInt8}),
        x, y, latin1(string))
end

function inqtextext(x::Real, y::Real, string)
  tbx = Cdouble[0, 0, 0, 0]
  tby = Cdouble[0, 0, 0, 0]
  ccall( (:gr_inqtextext, libGR),
        Void,
        (Float64, Float64, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble}),
        x, y, latin1(string), tbx, tby)
  return tbx, tby
end

"""
    axes(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real)

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
function axes(x_tick::Real, y_tick::Real, x_org::Real, y_org::Real, major_x::Int, major_y::Int, tick_size::Real)
  ccall( (:gr_axes, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32, Float64),
        x_tick, y_tick, x_org, y_org, major_x, major_y, tick_size)
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
  ccall( (:gr_grid, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32),
        x_tick, y_tick, x_org, y_org, major_x, major_y)
end

function grid3d(x_tick::Real, y_tick::Real, z_tick::Real, x_org::Real, y_org::Real, z_org::Real, major_x::Int, major_y::Int, major_z::Int)
  ccall( (:gr_grid3d, libGR),
        Void,
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
  assert(length(px) == length(py) == length(e1) == length(e2))
  n = length(px)
  ccall( (:gr_verrorbars, libGR),
        Void,
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
  assert(length(px) == length(py) == length(e1) == length(e2))
  n = length(px)
  ccall( (:gr_herrorbars, libGR),
        Void,
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
  assert(length(px) == length(py) == length(pz))
  n = length(px)
  ccall( (:gr_polyline3d, libGR),
        Void,
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
  assert(length(px) == length(py) == length(pz))
  n = length(px)
  ccall( (:gr_polymarker3d, libGR),
        Void,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        n, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz))
end

function axes3d(x_tick::Real, y_tick::Real, z_tick::Real, x_org::Real, y_org::Real, z_org::Real, major_x::Int, major_y::Int, major_z::Int, tick_size::Real)
  ccall( (:gr_axes3d, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Float64, Float64, Int32, Int32, Int32, Float64),
        x_tick, y_tick, z_tick, x_org, y_org, z_org, major_x, major_y, major_z, tick_size)
end

"""
    titles3d(x_title, y_title, z_title)

Display axis titles just outside of their respective axes.

**Parameters:**

`x_title`, `y_title`, `z_title` :
    The text to be displayed on each axis

"""
function titles3d(x_title, y_title, z_title)
  ccall( (:gr_titles3d, libGR),
        Void,
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
  if typeof(pz) == Function
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
    ccall( (:gr_surface, libGR),
          Void,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, pz), option)
  else
    println("Arrays have incorrect length or dimension.")
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
  if typeof(pz) == Function
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
    ccall( (:gr_contour, libGR),
          Void,
          (Int32, Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, nh, convert(Vector{Float64}, px), convert(Vector{Float64}, py), convert(Vector{Float64}, h), convert(Vector{Float64}, pz), major_h)
  else
    println("Arrays have incorrect length or dimension.")
  end
end

function hexbin(x, y, nbins)
  assert(length(x) == length(y))
  n = length(x)
  cntmax = ccall( (:gr_hexbin, libGR),
                 Int32,
                 (Int32, Ptr{Float64}, Ptr{Float64}, Int32),
                 n, convert(Vector{Float64}, x), convert(Vector{Float64}, y), nbins)
  return cntmax
end

function setcolormap(index::Int)
  ccall( (:gr_setcolormap, libGR),
        Void,
        (Int32, ),
        index)
end

function colorbar()
  ccall( (:gr_colorbar, libGR),
        Void,
        ()
        )
end

function inqcolor(color::Int)
  rgb = Cint[0]
  ccall( (:gr_inqcolor, libGR),
        Void,
        (Int32, Ptr{Int32}),
        color, rgb)
  return rgb[1]
end

function inqcolorfromrgb(red::Real, green::Real, blue::Real)
  color = ccall( (:gr_inqcolorfromrgb, libGR),
                Int32,
                (Float64, Float64, Float64),
                red, green, blue)
  return color
end

function hsvtorgb(h::Real, s::Real, v::Real)
  r = Cdouble[0]
  g = Cdouble[0]
  b = Cdouble[0]
  ccall( (:gr_hsvtorgb, libGR),
        Void,
        (Float64, Float64, Float64, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        h, s, v, r, g, b)
  return r[1], g[1], b[1]
end

function tick(amin::Real, amax::Real)
  return ccall( (:gr_tick, libGR),
               Float64,
               (Float64, Float64),
               amin, amax)
end

function validaterange(amin::Real, amax::Real)
  return ccall( (:gr_validaterange, libGR),
               Int32,
               (Float64, Float64),
               amin, amax)
end

function adjustlimits(amin::Real, amax::Real)
  _amin = Cdouble[amin]
  _amax = Cdouble[amax]
  ccall( (:gr_adjustlimits, libGR),
        Void,
        (Ptr{Float64}, Ptr{Float64}),
        _amin, _amax)
  return _amin[1], _amax[1]
end

function adjustrange(amin::Real, amax::Real)
  _amin = Cdouble[amin]
  _amax = Cdouble[amax]
  ccall( (:gr_adjustrange, libGR),
        Void,
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
  ccall( (:gr_beginprint, libGR),
        Void,
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
  ccall( (:gr_beginprintext, libGR),
        Void,
        (Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}),
        pathname, mode, fmt, orientation)
end

function endprint()
  ccall( (:gr_endprint, libGR),
        Void,
        ()
        )
end

function ndctowc(x::Real, y::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  ccall( (:gr_ndctowc, libGR),
        Void,
        (Ptr{Float64}, Ptr{Float64}),
        _x, _y)
  return _x[1], _y[1]
end

function wctondc(x::Real, y::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  ccall( (:gr_wctondc, libGR),
        Void,
        (Ptr{Float64}, Ptr{Float64}),
        _x, _y)
  return _x[1], _y[1]
end

function wc3towc(x::Real, y::Real, z::Real)
  _x = Cdouble[x]
  _y = Cdouble[y]
  _z = Cdouble[z]
  ccall( (:gr_wc3towc, libGR),
        Void,
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
  ccall( (:gr_drawrect, libGR),
        Void,
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
  ccall( (:gr_fillrect, libGR),
        Void,
        (Float64, Float64, Float64, Float64),
        xmin, xmax, ymin, ymax)
end

"""
    drawarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Int, a2::Int)

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
function drawarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Int, a2::Int)
  ccall( (:gr_drawarc, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32),
        xmin, xmax, ymin, ymax, a1, a2)
end

"""
    fillarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Int, a2::Int)

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
function fillarc(xmin::Real, xmax::Real, ymin::Real, ymax::Real, a1::Int, a2::Int)
  ccall( (:gr_fillarc, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32),
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
  len = length(points)
  ccall( (:gr_drawpath, libGR),
        Void,
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
  ccall( (:gr_setarrowstyle, libGR),
        Void,
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
  ccall( (:gr_setarrowsize, libGR),
        Void,
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
  ccall( (:gr_drawarrow, libGR),
        Void,
        (Float64, Float64, Float64, Float64),
        x1, y1, x2, y2)
end

function readimage(path)
  width = Cint[0]
  height = Cint[0]
  data = Array{Ptr{UInt32}}(1)
  ccall( (:gr_readimage, libGR),
        Void,
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
  ccall( (:gr_drawimage, libGR),
        Void,
        (Float64, Float64, Float64, Float64, Int32, Int32, Ptr{UInt32}, Int32),
        xmin, xmax, ymin, ymax, width, height, convert(Vector{UInt32}, data), model)
end

function importgraphics(path)
  ccall( (:gr_importgraphics, libGR),
        Void,
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
  ccall( (:gr_setshadow, libGR),
        Void,
        (Float64, Float64, Float64),
        offsetx, offsety, blur)
end

"""
    settransparency(alpha::Real)

Set the value of the alpha component associated with GR colors

**Parameters:**

`alpha` :
    An alpha value (0.0 - 1.0)

"""
function settransparency(alpha::Real)
  ccall( (:gr_settransparency, libGR),
        Void,
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
  assert(length(mat) == 6)
  ccall( (:gr_setcoordxform, libGR),
        Void,
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
  ccall( (:gr_begingraphics, libGR),
        Void,
        (Ptr{Cchar}, ),
        path)
end

function endgraphics()
  ccall( (:gr_endgraphics, libGR),
        Void,
        ()
        )
end

function getgraphics()
  string = ccall( (:gr_getgraphics, libGR),
                 Ptr{Cchar},
                 (),
                 )
  return string != C_NULL ? unsafe_string(string) : ""
end

function drawgraphics(string)
  ret = ccall( (:gr_drawgraphics, libGR),
              Int32,
              (Ptr{Cchar}, ),
              string)
  return int(ret)
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
  ccall( (:gr_mathtex, libGR),
        Void,
        (Float64, Float64, Ptr{Cchar}),
        x, y, string)
end

ASF_BUNDLED = 0
ASF_INDIVIDUAL = 1

NOCLIP = 0
CLIP = 1

COORDINATES_WC = 0
COORDINATES_NDC = 1

INTSTYLE_HOLLOW = 0
INTSTYLE_SOLID = 1
INTSTYLE_PATTERN = 2
INTSTYLE_HATCH = 3

TEXT_HALIGN_NORMAL = 0
TEXT_HALIGN_LEFT = 1
TEXT_HALIGN_CENTER = 2
TEXT_HALIGN_RIGHT = 3
TEXT_VALIGN_NORMAL = 0
TEXT_VALIGN_TOP = 1
TEXT_VALIGN_CAP = 2
TEXT_VALIGN_HALF = 3
TEXT_VALIGN_BASE = 4
TEXT_VALIGN_BOTTOM = 5

TEXT_PATH_RIGHT = 0
TEXT_PATH_LEFT = 1
TEXT_PATH_UP = 2
TEXT_PATH_DOWN = 3

TEXT_PRECISION_STRING = 0
TEXT_PRECISION_CHAR = 1
TEXT_PRECISION_STROKE = 2

LINETYPE_SOLID = 1
LINETYPE_DASHED = 2
LINETYPE_DOTTED = 3
LINETYPE_DASHED_DOTTED = 4
LINETYPE_DASH_2_DOT = -1
LINETYPE_DASH_3_DOT = -2
LINETYPE_LONG_DASH = -3
LINETYPE_LONG_SHORT_DASH = -4
LINETYPE_SPACED_DASH = -5
LINETYPE_SPACED_DOT = -6
LINETYPE_DOUBLE_DOT = -7
LINETYPE_TRIPLE_DOT = -8

MARKERTYPE_DOT = 1
MARKERTYPE_PLUS = 2
MARKERTYPE_ASTERISK = 3
MARKERTYPE_CIRCLE = 4
MARKERTYPE_DIAGONAL_CROSS = 5
MARKERTYPE_SOLID_CIRCLE = -1
MARKERTYPE_TRIANGLE_UP = -2
MARKERTYPE_SOLID_TRI_UP = -3
MARKERTYPE_TRIANGLE_DOWN = -4
MARKERTYPE_SOLID_TRI_DOWN = -5
MARKERTYPE_SQUARE = -6
MARKERTYPE_SOLID_SQUARE = -7
MARKERTYPE_BOWTIE = -8
MARKERTYPE_SOLID_BOWTIE = -9
MARKERTYPE_HOURGLASS = -10
MARKERTYPE_SOLID_HGLASS = -11
MARKERTYPE_DIAMOND = -12
MARKERTYPE_SOLID_DIAMOND = -13
MARKERTYPE_STAR = -14
MARKERTYPE_SOLID_STAR = -15
MARKERTYPE_TRI_UP_DOWN = -16
MARKERTYPE_SOLID_TRI_RIGHT = -17
MARKERTYPE_SOLID_TRI_LEFT = -18
MARKERTYPE_HOLLOW_PLUS = -19
MARKERTYPE_SOLID_PLUS = -20
MARKERTYPE_PENTAGON = -21
MARKERTYPE_HEXAGON = -22
MARKERTYPE_HEPTAGON = -23
MARKERTYPE_OCTAGON = -24
MARKERTYPE_STAR_4 = -25
MARKERTYPE_STAR_5 = -26
MARKERTYPE_STAR_6 = -27
MARKERTYPE_STAR_7 = -28
MARKERTYPE_STAR_8 = -29
MARKERTYPE_VLINE = -30
MARKERTYPE_HLINE = -31
MARKERTYPE_OMARK = -32

OPTION_X_LOG = 1
OPTION_Y_LOG = 2
OPTION_Z_LOG = 4
OPTION_FLIP_X = 8
OPTION_FLIP_Y = 16
OPTION_FLIP_Z = 32

OPTION_LINES = 0
OPTION_MESH = 1
OPTION_FILLED_MESH = 2
OPTION_Z_SHADED_MESH = 3
OPTION_COLORED_MESH = 4
OPTION_CELL_ARRAY = 5
OPTION_SHADED_MESH = 6

MODEL_RGB = 0
MODEL_HSV = 1

COLORMAP_UNIFORM = 0
COLORMAP_TEMPERATURE = 1
COLORMAP_GRAYSCALE = 2
COLORMAP_GLOWING = 3
COLORMAP_RAINBOWLIKE = 4
COLORMAP_GEOLOGIC = 5
COLORMAP_GREENSCALE = 6
COLORMAP_CYANSCALE = 7
COLORMAP_BLUESCALE = 8
COLORMAP_MAGENTASCALE = 9
COLORMAP_REDSCALE = 10
COLORMAP_FLAME = 11
COLORMAP_BROWNSCALE = 12
COLORMAP_PILATUS = 13
COLORMAP_AUTUMN = 14
COLORMAP_BONE = 15
COLORMAP_COOL = 16
COLORMAP_COPPER = 17
COLORMAP_GRAY = 18
COLORMAP_HOT = 19
COLORMAP_HSV = 20
COLORMAP_JET = 21
COLORMAP_PINK = 22
COLORMAP_SPECTRAL = 23
COLORMAP_SPRING = 24
COLORMAP_SUMMER = 25
COLORMAP_WINTER = 26
COLORMAP_GIST_EARTH = 27
COLORMAP_GIST_HEAT = 28
COLORMAP_GIST_NCAR = 29
COLORMAP_GIST_RAINBOW = 30
COLORMAP_GIST_STERN = 31
COLORMAP_AFMHOT = 32
COLORMAP_BRG = 33
COLORMAP_BWR = 34
COLORMAP_COOLWARM = 35
COLORMAP_CMRMAP = 36
COLORMAP_CUBEHELIX = 37
COLORMAP_GNUPLOT = 38
COLORMAP_GNUPLOT2 = 39
COLORMAP_OCEAN = 40
COLORMAP_RAINBOW = 41
COLORMAP_SEISMIC = 42
COLORMAP_TERRAIN = 43
COLORMAP_VIRIDIS = 44
COLORMAP_INFERNO = 45
COLORMAP_PLASMA = 46
COLORMAP_MAGMA = 47

FONT_TIMES_ROMAN = 101
FONT_TIMES_ITALIC = 102
FONT_TIMES_BOLD = 103
FONT_TIMES_BOLDITALIC = 104
FONT_HELVETICA = 105
FONT_HELVETICA_OBLIQUE = 106
FONT_HELVETICA_BOLD = 107
FONT_HELVETICA_BOLDOBLIQUE = 108
FONT_COURIER = 109
FONT_COURIER_OBLIQUE = 110
FONT_COURIER_BOLD = 111
FONT_COURIER_BOLDOBLIQUE = 112
FONT_SYMBOL = 113
FONT_BOOKMAN_LIGHT = 114
FONT_BOOKMAN_LIGHTITALIC = 115
FONT_BOOKMAN_DEMI = 116
FONT_BOOKMAN_DEMIITALIC = 117
FONT_NEWCENTURYSCHLBK_ROMAN = 118
FONT_NEWCENTURYSCHLBK_ITALIC = 119
FONT_NEWCENTURYSCHLBK_BOLD = 120
FONT_NEWCENTURYSCHLBK_BOLDITALIC = 121
FONT_AVANTGARDE_BOOK = 122
FONT_AVANTGARDE_BOOKOBLIQUE = 123
FONT_AVANTGARDE_DEMI = 124
FONT_AVANTGARDE_DEMIOBLIQUE = 125
FONT_PALATINO_ROMAN = 126
FONT_PALATINO_ITALIC = 127
FONT_PALATINO_BOLD = 128
FONT_PALATINO_BOLDITALIC = 129
FONT_ZAPFCHANCERY_MEDIUMITALIC = 130
FONT_ZAPFDINGBATS = 131

PATH_STOP      = 0x00
PATH_MOVETO    = 0x01
PATH_LINETO    = 0x02
PATH_CURVE3    = 0x03
PATH_CURVE4    = 0x04
PATH_CLOSEPOLY = 0x4f

MPL_SUPPRESS_CLEAR = 1
MPL_POSTPONE_UPDATE = 2

# GR3 functions
include("gr3.jl")

const gr3 = GR.GR3

# Convenience functions
include("jlgr.jl")

colormap() = jlgr.colormap()
figure(; kwargs...) = jlgr.figure(; kwargs...)
gcf() = jlgr.gcf()
hold(flag) = jlgr.hold(flag)
usecolorscheme(index) = jlgr.usecolorscheme(index)
subplot(m, n, p) = jlgr.subplot(m, n, p)
plot(args...; kwargs...) = jlgr.plot(args...; kwargs...)
oplot(args...; kwargs...) = jlgr.oplot(args...; kwargs...)
semilogx(args...; kwargs...) = jlgr.plot(args...; kwargs..., xlog=true)
semilogy(args...; kwargs...) = jlgr.plot(args...; kwargs..., ylog=true)
loglog(args...; kwargs...) = jlgr.plot(args...; kwargs..., xlog=true, ylog=true)
scatter(args...; kwargs...) = jlgr.scatter(args...; kwargs...)
stem(args...; kwargs...) = jlgr.stem(args...; kwargs...)
histogram(x; kwargs...) = jlgr.histogram(x; kwargs...)
contour(args...; kwargs...) = jlgr.contour(args...; kwargs...)
contourf(args...; kwargs...) = jlgr.contourf(args...; kwargs...)
hexbin(args...; kwargs...) = jlgr.hexbin(args...; kwargs...)
heatmap(D; kwargs...) = jlgr.heatmap(D; kwargs...)
wireframe(args...; kwargs...) = jlgr.wireframe(args...; kwargs...)
surface(args...; kwargs...) = jlgr.surface(args...; kwargs...)
plot3(args...; kwargs...) = jlgr.plot3(args...; kwargs...)
scatter3(args...; kwargs...) = jlgr.scatter3(args...; kwargs...)
title(s) = jlgr.title(s)
xlabel(s) = jlgr.xlabel(s)
ylabel(s) = jlgr.ylabel(s)
legend(args...; kwargs...) = jlgr.legend(args...; kwargs...)
xlim(a) = jlgr.xlim(a)
ylim(a) = jlgr.ylim(a)
savefig(filename) = jlgr.savefig(filename)
meshgrid(vx, vy) = jlgr.meshgrid(vx, vy)
meshgrid(vx, vy, vz) = jlgr.meshgrid(vx, vy, vz)
peaks(n...) = jlgr.peaks(n...)
imshow(I; kwargs...) = jlgr.imshow(I; kwargs...)
isosurface(V; kwargs...) = jlgr.isosurface(V; kwargs...)
cart2sph(x, y, z) = jlgr.cart2sph(x, y, z)
sph2cart(θ, ϕ, r) = jlgr.sph2cart(θ, ϕ, r)
polar(args...; kwargs...) = jlgr.polar(args...; kwargs...)
trisurf(args...; kwargs...) = jlgr.trisurf(args...; kwargs...)
tricont(args...; kwargs...) = jlgr.tricont(args...; kwargs...)
mainloop() = jlgr.mainloop()

type SVG
   s::Array{UInt8}
end
Base.show(io::IO, ::MIME"image/svg+xml", x::SVG) = write(io, x.s)

type PNG
   s::Array{UInt8}
end
Base.show(io::IO, ::MIME"image/png", x::PNG) = write(io, x.s)

type HTML
   s::AbstractString
end
Base.show(io::IO, ::MIME"text/html", x::HTML) = print(io, x.s)

function _readfile(path)
    data = Array{UInt8}(filesize(path))
    s = open(path, "r")
    read!(s, data)
end

function isinline()
    global mime_type
    return !(mime_type in (None, "mov"))
end

function displayname()
    global display_name
    return display_name
end

function startserver()
    global msgs

    @eval import WebSockets
    @eval import HttpServer

    msgs = []
    app = WebSockets.WebSocketHandler() do req, client
        while true
            msg = WebSockets.read(client)
            if startswith(unsafe_string(msg), "ready")
                if length(msgs) != 0
                    WebSockets.write(client, msgs[1])
                    shift!(msgs)
                else
                    WebSockets.write(client, "busy")
                end
            end
        end
    end

    server = HttpServer.Server(app)
    @async begin
        HttpServer.run(server, 8889)
    end

    if !isfile("gr.js")
        symlink(joinpath(dirname(@__FILE__), "gr.js"), "gr.js")
    end

    return HTML("""\
<canvas id="canvas" width="600" height="450"></canvas>\
<script type="text/javascript" src="gr.js"></script>\
<script>GR.ready(\
  function() {\
    var ws = new WebSocket("ws://localhost:8889/");\
    ws.onopen = function() {\
      ws.send("ready");\
    };\
    ws.onmessage = function(ev) {\
      if (ev.data == "busy") {\
        setTimeout(function() {ws.send("ready");}, 10);\
      } else {\
        gr_clearws();\
        gr_drawgraphics(window.atob(ev.data));\
        ws.send("ready");\
      };\
    };\
  }\
);</script>""")
end

function inline(mime="svg", scroll=true)
    global mime_type, figure_count, msgs
    if mime_type != mime
        if mime == "iterm"
            ENV["GKS_WSTYPE"] = "pdf"
        elseif mime == "mlterm"
            ENV["GKS_WSTYPE"] = "six"
        elseif mime == "atom"
            ENV["GKS_WSTYPE"] = "svg"
            @eval using Atom
            @eval import Atom: Media, PlotPane
        elseif mime == "js"
            ENV["GKS_WSTYPE"] = "nul"
        else
            ENV["GKS_WSTYPE"] = mime
        end
        emergencyclosegks()
        mime_type = mime
        if mime == "js"
            startserver()
        end
    end
    figure_count = scroll ? None : 0
    mime_type
end

function show()
    global mime_type, figure_count, msgs

    emergencyclosegks()
    if mime_type == "svg"
        content = SVG(_readfile("gks.svg"))
        return content
    elseif mime_type == "png"
        content = PNG(_readfile("gks.png"))
        return content
    elseif mime_type == "mov"
        content = HTML(string("""<video autoplay controls><source type="video/mp4" src="data:video/mp4;base64,""", base64encode(open(read,"gks.mov")),""""></video>"""))
        return content
    elseif mime_type == "iterm"
        content = string("\033]1337;File=inline=1;height=24;preserveAspectRatio=0:", base64encode(open(read,"gks.pdf")), "\a")
        if figure_count != None
            figure_count += 1
            (figure_count > 1) && print("\e[24A")
        end
        println(content)
        return nothing
    elseif mime_type == "mlterm"
        content = read("gks.six")
        write(content)
        return nothing
    elseif mime_type == "atom"
        bg = jlgr.background
        content = Base.HTML(string("""<div style="display: inline-block; background: #""", hex(bg, 6), """;">""", readstring("gks.svg"), """</div>"""))
        Atom.render(Atom.PlotPane(), content)
        return nothing
    elseif mime_type == "js"
        if msgs != None
            endgraphics()
            push!(msgs, Base.base64encode(getgraphics()))
        end
    end
    return None
end

function setregenflags(flags=0)
  ccall( (:gr_setregenflags, libGR),
        Void,
        (Int32, ),
        flags)
end

function inqregenflags()
  flags = ccall( (:gr_inqregenflags, libGR),
                Int32,
                ()
                )
  return flags
end

function savestate()
  ccall( (:gr_savestate, libGR),
        Void,
        ()
        )
end

function restorestate()
  ccall( (:gr_restorestate, libGR),
        Void,
        ()
        )
end

function selectcontext(context::Int)
  ccall( (:gr_selectcontext, libGR),
        Void,
        (Int32, ),
        context)
end

function destroycontext(context::Int)
  ccall( (:gr_destroycontext, libGR),
        Void,
        (Int32, ),
        context)
end

function uselinespec(linespec)
  return ccall( (:gr_uselinespec, libGR),
               Int32,
               (Ptr{Cchar}, ),
               linespec)
end

function delaunay(x, y)
  assert(length(x) == length(y))
  npoints = length(x)
  ntri = Cint[0]
  dim = Cint[3]
  triangles = Array{Ptr{Int32}}(1)
  ccall( (:gr_delaunay, libGR),
        Void,
        (Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Ptr{Int32}}),
        npoints, convert(Vector{Float64}, x), convert(Vector{Float64}, y),
        ntri, triangles)
  if ntri[1] > 0
    tri = unsafe_wrap(Array{Int32}, triangles[1], (dim[1], ntri[1]))
    return Int(ntri[1]), tri'+1
  else
    return 0, zeros(Int32, 0)
  end
end

function interp2(X, Y, Z, Xq, Yq, method::Int=0, extrapval=0)
  nx = length(X)
  ny = length(Y)
  if typeof(Z) == Function
    f = Z
    Z = Float64[f(x,y) for y in Y, x in X]
  end
  nz = length(Z)
  if ndims(Z) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(Z) == 2
    out_of_bounds = size(Z)[1] != nx || size(Z)[2] != ny
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
    ccall( (:gr_interp2, libGR),
          Void,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Cdouble}, Int32, Float64),
          nx, ny, convert(Vector{Float64}, X), convert(Vector{Float64}, Y), convert(Vector{Float64}, Z), nxq, nyq, convert(Vector{Float64}, Xq), convert(Vector{Float64}, Yq), Zq, method, extrapval)
  end
  reshape(Zq, nxq, nyq)
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
  ccall( (:gr_trisurface, libGR),
        Void,
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
  ccall( (:gr_tricontour, libGR),
        Void,
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
    ccall( (:gr_gradient, libGR),
          Void,
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
    ccall( (:gr_quiver, libGR),
          Void,
          (Int32, Int32, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Int32),
          nx, ny, convert(Vector{Float64}, x), convert(Vector{Float64}, y), convert(Vector{Float64}, u), convert(Vector{Float64}, v), convert(Int32, color))
  else
    println("Arrays have incorrect length or dimension.")
  end
end

end # module
