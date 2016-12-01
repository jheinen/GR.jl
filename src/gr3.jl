module GR3

using Compat

import GR

const None = Union{}

macro triplet(t)
    :( Tuple{$t, $t, $t} )
end

macro ArrayToVector(ctype, data)
    return :( convert(Vector{$ctype}, vec($data)) )
end

type PNG
   s::Array{UInt8}
end
@compat Base.show(io::IO, ::MIME"image/png", x::PNG) = write(io, x.s)

type HTML
   s::AbstractString
end
@compat Base.show(io::IO, ::MIME"text/html", x::HTML) = print(io, x.s)

function _readfile(path)
    data = Array(UInt8, filesize(path))
    s = open(path, "r")
    read!(s, data)
end

type GR3Exception <: Exception
    msg::AbstractString
end
Base.showerror(io::IO, e::GR3Exception) = print(io, e.msg);


const msgs = [ "none", "invalid value", "invalid attribute", "init failed",
               "OpenGL error", "out of memory", "not initialized",
               "camera not initialized", "unknown file extension",
               "cannot open file", "export failed" ]

function _check_error()
  line = Cint[0]
  file = Ptr{UInt8}[0]
  error_code = ccall((:gr3_geterror, GR.libGR3), Int32, (Int32, Ptr{Cint}, Ptr{Ptr{UInt8}}), 1, line, file)
  if (error_code != 0)
    line = line[1]
    file = Compat.unsafe_string(file[1])
    if 0 <= error_code < length(msgs)
      msg = msgs[error_code + 1]
    else
      msg = "unknown error"
    end
    message = string("GR3 error (", file, ", l. ", line, "): ", msg)
    throw(GR3Exception(message))
  end
end

function init(attrib_list)
  ccall((:gr3_init, GR.libGR3), Int32, (Ptr{Int}, ), attrib_list)
  _check_error()
end
export init

function free(pointer)
  ccall((:gr3_free, GR.libGR3), Void, (Ptr{Void}, ), pointer)
  _check_error()
end
export free

function terminate()
  ccall((:gr3_terminate, GR.libGR3), Void, ())
  _check_error()
end
export terminate

function useframebuffer(framebuffer)
  ccall((:gr3_useframebuffer, GR.libGR3), Void, (UInt32, ), framebuffer)
  _check_error()
end
export useframebuffer

function usecurrentframebuffer()
  ccall((:gr3_usecurrentframebuffer, GR.libGR3), Void, ())
  _check_error()
end
export usecurrentframebuffer

function getimage(width, height, use_alpha=true)
  bpp = use_alpha ? 4 : 3
  bitmap = zeros(UInt8, width * height * bpp)
  ccall((:gr3_getimage, GR.libGR3),
        Int32,
        (Int32, Int32, Int32, Ptr{UInt8}),
        width, height, use_alpha, bitmap)
  _check_error()
  return bitmap
end
export getimage

function save(filename, width, height)
  ccall((:gr3_export, GR.libGR3),
        Int32,
        (Ptr{Cchar}, Int32, Int32),
        filename, width, height)
  _check_error()
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
  _check_error()
  Compat.unsafe_string(val)
end
export getrenderpathstring

function drawimage(xmin, xmax, ymin, ymax, pixel_width, pixel_height, window)
  ccall((:gr3_drawimage, GR.libGR3),
        Int32,
        (Float32, Float32, Float32, Float32, Int32, Int32, Int32),
        xmin, xmax, ymin, ymax, pixel_width, pixel_height, window)
  _check_error()
end
export drawimage

function createmesh(n, vertices, normals, colors)
  mesh = Cint[0]
  _vertices = [ Float32(x) for x in vertices ]
  _normals = [ Float32(x) for x in normals ]
  _colors = [ Float32(x) for x in colors ]
  ccall((:gr3_createmesh, GR.libGR3),
        Int32,
        (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        mesh, n, @ArrayToVector(Float32, _vertices), @ArrayToVector(Float32, _normals), @ArrayToVector(Float32, _colors))
  _check_error()
  return mesh[1]
end
export createmesh

function createindexedmesh(num_vertices, vertices, normals, colors, num_indices, indices)
  mesh = Cint[0]
  _vertices = [ Float32(x) for x in vertices ]
  _normals = [ Float32(x) for x in normals ]
  _colors = [ Float32(x) for x in colors ]
  _indices = [ Float32(x) for x in indices ]
  ccall((:gr3_createindexedmesh, GR.libGR3),
        Int32,
        (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32, Ptr{Int32}),
        mesh, num_vertices, @ArrayToVector(Float32, _vertices), @ArrayToVector(Float32, _normals), @ArrayToVector(Float32, _colors), num_indices, @ArrayToVector(Float32, _indices))
  _check_error()
  return mesh[1]
end
export createindexedmesh

function drawmesh(mesh::Int32, n, positions::@triplet(Real), directions::@triplet(Real), ups::@triplet(Real), colors::@triplet(Real), scales::@triplet(Real))
  _positions = [ Float32(x) for x in positions ]
  _directions = [ Float32(x) for x in directions ]
  _ups = [ Float32(x) for x in ups ]
  _colors = [ Float32(x) for x in colors ]
  _scales = [ Float32(x) for x in scales ]
  ccall((:gr3_drawmesh, GR.libGR3),
        Void,
        (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        mesh, n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _ups), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _scales))
  _check_error()
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
          @ArrayToVector(Float32, heightmap), num_columns, num_rows)
    _check_error()
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
    _positions = [ Float32(x) for x in positions ]
    _scales = [ Float32(x) for x in scales ]
    ccall((:gr3_drawheightmap, GR.libGR3),
          Void,
          (Ptr{Float32}, Int32, Int32, Ptr{Float32}, Ptr{Float32}),
          @ArrayToVector(Float32, heightmap), num_columns, num_rows, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _scales))
    _check_error()
  else
    println("Array has incorrect length or dimension.")
  end
end
export drawheightmap

function deletemesh(mesh)
  ccall((:gr3_deletemesh, GR.libGR3), Void, (Int32, ), mesh)
  _check_error()
end
export deletemesh

function setquality(quality)
  ccall((:gr3_setquality, GR.libGR3), Void, (Int32, ), quality)
  _check_error()
end
export setquality

function clear()
  ccall((:gr3_clear, GR.libGR3), Void, ())
  _check_error()
end
export clear

function cameralookat(camera_x, camera_y, camera_z,
                      center_x, center_y, center_z,
                      up_x, up_y, up_z)
  ccall((:gr3_cameralookat, GR.libGR3),
        Void,
        (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32),
        camera_x, camera_y, camera_z, center_x, center_y, center_z, up_x, up_y, up_z)
  _check_error()
end
export cameralookat

function setcameraprojectionparameters(vertical_field_of_view, zNear, zFar)
  ccall((:gr3_setcameraprojectionparameters, GR.libGR3),
        Void,
        (Float32, Float32, Float32),
        vertical_field_of_view, zNear, zFar)
  _check_error()
end
export setcameraprojectionparameters

function setlightdirection(x, y, z)
  ccall((:gr3_setlightdirection, GR.libGR3),
        Void,
        (Float32, Float32, Float32),
        x, y, z)
  _check_error()
end
export setlightdirection

function drawcylindermesh(n, positions, directions, colors, radii, lengths)
  _positions = [ Float32(x) for x in positions ]
  _directions = [ Float32(x) for x in directions ]
  _colors = [ Float32(x) for x in colors ]
  _radii = [ Float32(x) for x in radii ]
  _lengths = [ Float32(x) for x in lengths ]
  ccall((:gr3_drawcylindermesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _radii), @ArrayToVector(Float32, _lengths))
  _check_error()
end
export drawcylindermesh

function drawconemesh(n, positions, directions, colors, radii, lengths)
  _positions = [ Float32(x) for x in positions ]
  _directions = [ Float32(x) for x in directions ]
  _colors = [ Float32(x) for x in colors ]
  _radii = [ Float32(x) for x in radii ]
  _lengths = [ Float32(x) for x in lengths ]
  ccall((:gr3_drawconemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _radii), @ArrayToVector(Float32, _lengths))
  _check_error()
end
export drawconemesh

function drawspheremesh(n, positions, colors, radii)
  _positions = [ Float32(x) for x in positions ]
  _colors = [ Float32(x) for x in colors ]
  _radii = [ Float32(x) for x in radii ]
  ccall((:gr3_drawspheremesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _radii))
  _check_error()
end
export drawspheremesh

function drawcubemesh(n, positions, directions, ups, colors, scales)
  _positions = [ Float32(x) for x in positions ]
  _directions = [ Float32(x) for x in directions ]
  _ups = [ Float32(x) for x in ups ]
  _colors = [ Float32(x) for x in colors ]
  _scales = [ Float32(x) for x in scales ]
  ccall((:gr3_drawcubemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _ups), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _scales))
  _check_error()
end
export drawcubemesh

function setbackgroundcolor(red, green, blue, alpha)
  ccall((:gr3_setbackgroundcolor, GR.libGR3),
        Void,
        (Float32, Float32, Float32, Float32),
        red, green, blue, alpha)
  _check_error()
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
              mesh, @ArrayToVector(UInt16, data), UInt16(isolevel), dim_x, dim_y, dim_z, stride_x, stride_y, stride_z, step_x, step_y, step_z, offset_x, offset_y, offset_z)
  _check_error()
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
    if ndims(pz) == 2
      pz = reshape(pz, nx * ny)
    end
    _px = [ Float32(x) for x in px ]
    _py = [ Float32(y) for y in py ]
    _pz = [ Float32(z) for z in pz ]
    ccall((:gr3_surface, GR.libGR3),
          Void,
          (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32),
          nx, ny, @ArrayToVector(Float32, _px), @ArrayToVector(Float32, _py), @ArrayToVector(Float32, _pz), option)
    _check_error()
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
