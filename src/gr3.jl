module GR3

import Base.writemime

import GR

if VERSION < v"0.4-"
  typealias AbstractString String
  typealias UInt8 Uint8
  typealias UInt16 Uint16
  typealias UInt32 Uint32
else
  const None = Union{}
end

if VERSION >= v"0.4-"
  macro _float32(x)
    :( Float32($x) )
  end
  macro _uint16(x)
    :( UInt16($x) )
  end
  macro triplet(t)
    :( Tuple{$t, $t, $t} )
  end
else
  macro _float32(x)
    :( float32($x) )
  end
  macro _uint16(x)
    :( uint16($x) )
  end
  macro triplet(t)
    :( ($t, $t, $t) )
  end
end

type PNG
   s::Array{UInt8}
end
writemime(io::IO, ::MIME"image/png", x::PNG) = write(io, x.s)

type HTML
   s::AbstractString
end
writemime(io::IO, ::MIME"text/html", x::HTML) = print(io, x.s)

function _readfile(path)
    data = Array(UInt8, filesize(path))
    s = open(path, "r")
    bytestring(read!(s, data))
end

function perror(error_code)
  msgs = [ "none", "invalid value", "invalid attribute", "init failed",
           "OpenGL error", "out of memory", "not initialized",
           "camera not initialized", "unknown file extension",
           "cannot open file", "export failed" ]
  if 0 <= error_code < length(msgs)
    println("GR3 error: ", msgs[error_code + 1])
  else
    println("GR3: unknown error")
  end
end

function init(attrib_list)
  err = ccall((:gr3_init, GR.libGR3), Int32, (Ptr{Int}, ), attrib_list)
  if err != 0
    perror(err)
  end
end
export init

function free(pointer)
  ccall((:gr3_free, GR.libGR3), Void, (Ptr{Void}, ), pointer)
end
export free

function terminate()
  ccall((:gr3_terminate, GR.libGR3), Void, ())
end
export terminate

function getimage(width, height, use_alpha=true)
  bpp = use_alpha ? 4 : 3
  bitmap = zeros(UInt8, width * height * bpp)
  err = ccall((:gr3_getimage, GR.libGR3),
              Int32,
              (Int32, Int32, Int32, Ptr{UInt8}),
              width, height, use_alpha, bitmap)
  if err != 0
    perror(err)
  end
  return bitmap
end
export getimage

function save(filename, width, height)
  err = ccall((:gr3_export, GR.libGR3),
              Int32,
              (Ptr{Cchar}, Int32, Int32),
              filename, width, height)
  if err != 0
    perror(err)
  end
  ext = splitext(filename)[end:end][1]
  if ext == ".png"
    content = PNG(_readfile(filename))
  elseif ext == ".html"
    content = HTML(@sprintf("<iframe src=\"%s\" width=%d height=%d></iframe>", filename, width, height))
  else
    content = None
  end
  return content
end
export save

function getrenderpathstring()
  val = ccall((:gr3_getrenderpathstring, GR.libGR3),
              Ptr{UInt8}, (), )
  bytestring(val)
end
export getrenderpathstring

function drawimage(xmin, xmax, ymin, ymax, pixel_width, pixel_height, window)
  err = ccall((:gr3_drawimage, GR.libGR3),
              Int32,
              (Float32, Float32, Float32, Float32, Int32, Int32, Int32),
              xmin, xmax, ymin, ymax, pixel_width, pixel_height, window)
  if err != 0
    perror(err)
  end
end
export drawimage

function createmesh(n, vertices, normals, colors)
  mesh = Cint[0]
  _vertices = [ @_float32(x) for x in vertices ]
  _normals = [ @_float32(x) for x in normals ]
  _colors = [ @_float32(x) for x in colors ]
  err = ccall((:gr3_createmesh, GR.libGR3),
              Int32,
              (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
              mesh, n, convert(Vector{Float32}, _vertices), convert(Vector{Float32}, _normals), convert(Vector{Float32}, _colors))
  if err != 0
    perror(err)
  end
  return mesh[1]
end
export createmesh

function createindexedmesh(num_vertices, vertices, normals, colors, num_indices, indices)
  mesh = Cint[0]
  _vertices = [ @_float32(x) for x in vertices ]
  _normals = [ @_float32(x) for x in normals ]
  _colors = [ @_float32(x) for x in colors ]
  _indices = [ @_float32(x) for x in indices ]
  err = ccall((:gr3_createindexedmesh, GR.libGR3),
              Int32,
              (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32, Ptr{Int32}),
              mesh, num_vertices, convert(Vector{Float32}, _vertices), convert(Vector{Float32}, _normals), convert(Vector{Float32}, _colors), num_indices, convert(Vector{Float32}, _indices))
  if err != 0
    perror(err)
  end
  return mesh[1]
end
export createindexedmesh

function drawmesh(mesh::Int32, n, positions::@triplet(Real), directions::@triplet(Real), ups::@triplet(Real), colors::@triplet(Real), scales::@triplet(Real))
  _positions = [ @_float32(x) for x in positions ]
  _directions = [ @_float32(x) for x in directions ]
  _ups = [ @_float32(x) for x in ups ]
  _colors = [ @_float32(x) for x in colors ]
  _scales = [ @_float32(x) for x in scales ]
  ccall((:gr3_drawmesh, GR.libGR3),
        Void,
        (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        mesh, n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _ups), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _scales))
end
export drawmesh

function createheightmapmesh(heightmap, num_columns, num_rows)
  if num_columns * num_rows == length(heightmap)
    if ndims(heightmap) == 2
      heightmap = reshape(heightmap, num_columns * num_rows)
    end
    ccall((:gr3_createheightmapmesh, GR.libGR3),
          Void,
          (Ptr{Float32}, Int32, Int32),
          convert(Vector{Float32}, heightmap), num_columns, num_rows)
  else
    println("Array has incorrect length or dimension.")
  end
end
export createheightmapmesh

function drawheightmap(heightmap, num_columns, num_rows, positions, scales)
  if num_columns * num_rows == length(heightmap)
    if ndims(heightmap) == 2
      heightmap = reshape(heightmap, num_columns * num_rows)
    end
    _positions = [ @_float32(x) for x in positions ]
    _scales = [ @_float32(x) for x in scales ]
    ccall((:gr3_drawheightmap, GR.libGR3),
          Void,
          (Ptr{Float32}, Int32, Int32, Ptr{Float32}, Ptr{Float32}),
          convert(Vector{Float32}, heightmap), num_columns, num_rows, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _scales))
  else
    println("Array has incorrect length or dimension.")
  end
end
export drawheightmap

function deletemesh(mesh)
  ccall((:gr3_deletemesh, GR.libGR3), Void, (Int32, ), mesh)
end
export deletemesh

function setquality(quality)
  ccall((:gr3_setquality, GR.libGR3), Void, (Int32, ), quality)
end
export setquality

function clear()
  ccall((:gr3_clear, GR.libGR3), Void, ())
end
export clear

function cameralookat(camera_x, camera_y, camera_z,
                      center_x, center_y, center_z,
                      up_x, up_y, up_z)
  ccall((:gr3_cameralookat, GR.libGR3),
        Void,
        (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32),
        camera_x, camera_y, camera_z, center_x, center_y, center_z, up_x, up_y, up_z)
end
export cameralookat

function setcameraprojectionparameters(vertical_field_of_view, zNear, zFar)
  ccall((:gr3_setcameraprojectionparameters, GR.libGR3),
        Void,
        (Float32, Float32, Float32),
        vertical_field_of_view, zNear, zFar)
end
export setcameraprojectionparameters

function setlightdirection(x, y, z)
  ccall((:gr3_setlightdirection, GR.libGR3),
        Void,
        (Float32, Float32, Float32),
        x, y, z)
end
export setlightdirection

function drawcylindermesh(n, positions, directions, colors, radii, lengths)
  _positions = [ @_float32(x) for x in positions ]
  _directions = [ @_float32(x) for x in directions ]
  _colors = [ @_float32(x) for x in colors ]
  _radii = [ @_float32(x) for x in radii ]
  _lengths = [ @_float32(x) for x in lengths ]
  ccall((:gr3_drawcylindermesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii), convert(Vector{Float32}, _lengths))
end
export drawcylindermesh

function drawconemesh(n, positions, directions, colors, radii, lengths)
  _positions = [ @_float32(x) for x in positions ]
  _directions = [ @_float32(x) for x in directions ]
  _colors = [ @_float32(x) for x in colors ]
  _radii = [ @_float32(x) for x in radii ]
  _lengths = [ @_float32(x) for x in lengths ]
  ccall((:gr3_drawconemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii), convert(Vector{Float32}, _lengths))
end
export drawconemesh

function drawspheremesh(n, positions, colors, radii)
  _positions = [ @_float32(x) for x in positions ]
  _colors = [ @_float32(x) for x in colors ]
  _radii = [ @_float32(x) for x in radii ]
  ccall((:gr3_drawspheremesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii))
end
export drawspheremesh

function drawcubemesh(n, positions, directions, ups, colors, scales)
  _positions = [ @_float32(x) for x in positions ]
  _directions = [ @_float32(x) for x in directions ]
  _ups = [ @_float32(x) for x in ups ]
  _colors = [ @_float32(x) for x in colors ]
  _scales = [ @_float32(x) for x in scales ]
  ccall((:gr3_drawcubemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _ups), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _scales))
end
export drawcubemesh

function setbackgroundcolor(red, green, blue, alpha)
  ccall((:gr3_setbackgroundcolor, GR.libGR3),
        Void,
        (Float32, Float32, Float32, Float32),
        red, green, blue, alpha)
end
export setbackgroundcolor

function createisosurfacemesh(grid::Array{UInt16,3}, step::@triplet(Float64), offset::@triplet(Float64), isolevel::Int64)
  mesh = Cint[0]
  dim_x, dim_y, dim_z = size(grid)
  data = reshape(grid, dim_x * dim_y * dim_z)
  stride_x, stride_y, stride_z = strides(grid)
  step_x, step_y, step_z = [ float(x) for x in step ]
  offset_x, offset_y, offset_z = [ float(x) for x in offset ]
  err = ccall((:gr3_createisosurfacemesh, GR.libGR3),
              Int32,
              (Ptr{Cint}, Ptr{UInt16}, UInt16, Int32, Int32, Int32, Int32, Int32, Int32, Float64, Float64, Float64, Float64, Float64, Float64),
              mesh, convert(Vector{UInt16}, data), @_uint16(isolevel), dim_x, dim_y, dim_z, stride_x, stride_y, stride_z, step_x, step_y, step_z, offset_x, offset_y, offset_z)
  if err != 0
    perror(err)
  end
  return mesh[1]
end
export createisosurfacemesh

function surface(px, py, pz, option::Int)
  nx = length(px)
  ny = length(py)
  nz = length(pz)
  if ndims(pz) == 1
    out_of_bounds = nz != nx * ny
  elseif ndims(pz) == 2
    out_of_bounds = size(pz)[1] != nx || size(pz)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    _px = [ @_float32(x) for x in px ]
    _py = [ @_float32(y) for y in py ]
    _pz = [ @_float32(z) for z in pz ]
    ccall((:gr3_surface, GR.libGR3),
          Void,
          (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32),
          nx, ny, convert(Vector{Float32}, _px), convert(Vector{Float32}, _py), convert(Vector{Float32}, _pz), option)
  else
    println("Arrays have incorrect length or dimension.")
  end
end

IA_END_OF_LIST = 0
IA_FRAMEBUFFER_WIDTH = 1
IA_FRAMEBUFFER_HEIGHT = 2

ERROR_NONE = 0
ERROR_INVALID_VALUE = 1
ERROR_INVALID_ATTRIBUTE = 2
ERROR_INIT_FAILED = 3
ERROR_OPENGL_ERR = 4
ERROR_OUT_OF_MEM = 5
ERROR_NOT_INITIALIZED = 6
ERROR_CAMERA_NOT_INITIALIZED = 7
ERROR_UNKNOWN_FILE_EXTENSION = 8
ERROR_CANNOT_OPEN_FILE = 9
ERROR_EXPORT = 10

QUALITY_OPENGL_NO_SSAA  = 0
QUALITY_OPENGL_2X_SSAA  = 2
QUALITY_OPENGL_4X_SSAA  = 4
QUALITY_OPENGL_8X_SSAA  = 8
QUALITY_OPENGL_16X_SSAA = 16
QUALITY_POVRAY_NO_SSAA  = 0+1
QUALITY_POVRAY_2X_SSAA  = 2+1
QUALITY_POVRAY_4X_SSAA  = 4+1
QUALITY_POVRAY_8X_SSAA  = 8+1
QUALITY_POVRAY_16X_SSAA = 16+1

DRAWABLE_OPENGL = 1
DRAWABLE_GKS = 2

SURFACE_DEFAULT     =  0
SURFACE_NORMALS     =  1
SURFACE_FLAT        =  2
SURFACE_GRTRANSFORM =  4
SURFACE_GRCOLOR     =  8
SURFACE_GRZSHADED   = 16

end # module
