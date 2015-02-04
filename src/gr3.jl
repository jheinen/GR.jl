module GR3

import GR
import GetC.@getCFun

@getCFun GR.libGR3 init gr3_init(attrib_list::Ptr{Int})::Int
export init

@getCFun GR.libGR3 free gr3_free(pointer::Ptr{Void})::Void
export free 

@getCFun GR.libGR3 terminate gr3_terminate()::Void
export terminate

function getimage(width, height, use_alpha=true)
  bpp = use_alpha ? 4 : 3
  bitmap = zeros(Uint8, width * height * bpp)
  ccall( (:gr3_getimage, GR.libGR3),
        Void,
        (Int32, Int32, Int32, Ptr{Uint8}),
        width, height, use_alpha, bitmap)
  return bitmap
end
export getimage

@getCFun GR.libGR3 save gr3_export(filename::Ptr{Cchar}, width::Int32, height::Int32)::Void
export save

function getrenderpathstring()
  val = ccall( (:gr3_getrenderpathstring, GR.libGR3),
              Ptr{Uint8}, (), )
  bytestring(val)
end
export getrenderpathstring

@getCFun GR.libGR3 drawimage gr3_drawimage(xmin::Float32, xmax::Float32, ymin::Float32, ymax::Float32, pixel_width::Int32, pixel_height::Int32, window::Int32)::Void
export drawimage

function createmesh(n, vertices, normals, colors)
  mesh = Cint[0]
  _vertices = [ float32(x) for x in vertices ]
  _normals = [ float32(x) for x in normals ]
  _colors = [ float32(x) for x in colors ]
  ccall( (:gr3_createmesh, GR.libGR3),
        Void,
        (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        mesh, n, convert(Vector{Float32}, _vertices), convert(Vector{Float32}, _normals), convert(Vector{Float32}, _colors))
  return mesh[1]
end
export createmesh

function createindexedmesh(num_vertices, vertices, normals, colors, num_indices, indices)
  mesh = Cint[0]
  _vertices = [ float32(x) for x in vertices ]
  _normals = [ float32(x) for x in normals ]
  _colors = [ float32(x) for x in colors ]
  _indices = [ float32(x) for x in indices ]
  ccall( (:gr3_createindexedmesh, GR.libGR3),
        Void,
        (Ptr{Cint}, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32, Ptr{Int32}),
        mesh, num_vertices, convert(Vector{Float32}, _vertices), convert(Vector{Float32}, _normals), convert(Vector{Float32}, _colors), num_indices, convert(Vector{Float32}, _indices))
  return mesh[1]
end
export createindexedmesh

function drawmesh(mesh::Int32, n, positions::(Real,Real,Real), directions::(Real,Real,Real), ups::(Real,Real,Real), colors::(Real,Real,Real), scales::(Real,Real,Real))
  _positions = [ float32(x) for x in positions ]
  _directions = [ float32(x) for x in directions ]
  _ups = [ float32(x) for x in ups ]
  _colors = [ float32(x) for x in colors ]
  _scales = [ float32(x) for x in scales ]
  ccall( (:gr3_drawmesh, GR.libGR3),
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
    ccall( (:gr3_createheightmapmesh, GR.libGR3),
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
    _positions = [ float32(x) for x in positions ]
    _scales = [ float32(x) for x in scales ]
    ccall( (:gr3_drawheightmap, GR.libGR3),
          Void,
          (Ptr{Float32}, Int32, Int32, Ptr{Float32}, Ptr{Float32}),
          convert(Vector{Float32}, heightmap), num_columns, num_rows, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _scales))
  else
    println("Array has incorrect length or dimension.")
  end
end
export drawheightmap

@getCFun GR.libGR3 deletemesh gr3_deletemesh(mesh::Int32)::Void
export deletemesh

@getCFun GR.libGR3 setquality gr3_setquality(quality::Int32)::Void
export setquality

@getCFun GR.libGR3 clear gr3_clear()::Void
export clear

@getCFun GR.libGR3 cameralookat gr3_cameralookat(camera_x::Float32, camera_y::Float32, camera_z::Float32, center_x::Float32, center_y::Float32, center_z::Float32, up_x::Float32, up_y::Float32, up_z::Float32)::Void
export cameralookat

@getCFun GR.libGR3 setcameraprojectionparameters gr3_setcameraprojectionparameters(vertical_field_of_view::Float32, zNear::Float32, zFar::Float32)::Void
export setcameraprojectionparameters

@getCFun GR.libGR3 setlightdirection gr3_setlightdirection(x::Float32, y::Float32, z::Float32)::Void
export setlightdirection

function drawcylindermesh(n, positions, directions, colors, radii, lengths)
  _positions = [ float32(x) for x in positions ]
  _directions = [ float32(x) for x in directions ]
  _colors = [ float32(x) for x in colors ]
  _radii = [ float32(x) for x in radii ]
  _lengths = [ float32(x) for x in lengths ]
  ccall( (:gr3_drawcylindermesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii), convert(Vector{Float32}, _lengths))
end
export drawcylindermesh

function drawconemesh(n, positions, directions, colors, radii, lengths)
  _positions = [ float32(x) for x in positions ]
  _directions = [ float32(x) for x in directions ]
  _colors = [ float32(x) for x in colors ]
  _radii = [ float32(x) for x in radii ]
  _lengths = [ float32(x) for x in lengths ]
  ccall( (:gr3_drawconemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii), convert(Vector{Float32}, _lengths))
end
export drawconemesh

function drawspheremesh(n, positions, colors, radii)
  _positions = [ float32(x) for x in positions ]
  _colors = [ float32(x) for x in colors ]
  _radii = [ float32(x) for x in radii ]
  ccall( (:gr3_drawspheremesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _radii))
end
export drawspheremesh

function drawcubemesh(n, positions, directions, ups, colors, scales)
  _positions = [ float32(x) for x in positions ]
  _directions = [ float32(x) for x in directions ]
  _ups = [ float32(x) for x in ups ]
  _colors = [ float32(x) for x in colors ]
  _scales = [ float32(x) for x in scales ]
  ccall( (:gr3_drawcubemesh, GR.libGR3),
        Void,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, convert(Vector{Float32}, _positions), convert(Vector{Float32}, _directions), convert(Vector{Float32}, _ups), convert(Vector{Float32}, _colors), convert(Vector{Float32}, _scales))
end
export drawcubemesh

@getCFun GR.libGR3 setbackgroundcolor gr3_setbackgroundcolor(red::Float32, green::Float32, blue::Float32, alpha::Float32)::Void
export setbackgroundcolor

function createisosurfacemesh(grid::Array{Uint16,3}, step::(Float64,Float64,Float64), offset::(Float64,Float64,Float64), isolevel::Int64)
  mesh = Cint[0]
  dim_x, dim_y, dim_z = size(grid)
  data = reshape(grid, dim_x * dim_y * dim_z)
  stride_x, stride_y, stride_z = strides(grid)
  step_x, step_y, step_z = [ float(x) for x in step ]
  offset_x, offset_y, offset_z = [ float(x) for x in offset ]
  ret = ccall( (:gr3_createisosurfacemesh, GR.libGR3),
              Int,
              (Ptr{Cint}, Ptr{Uint16}, Uint16, Int32, Int32, Int32, Int32, Int32, Int32, Float64, Float64, Float64, Float64, Float64, Float64),
              mesh, convert(Vector{Uint16}, data), uint16(isolevel), dim_x, dim_y, dim_z, stride_x, stride_y, stride_z, step_x, step_y, step_z, offset_x, offset_y, offset_z)
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
    out_of_bounds = True
  end
  if !out_of_bounds
    ccall( (:gr3_surface, GR.libGR3),
          Void,
          (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32),
          nx, ny, convert(Vector{Float32}, px), convert(Vector{Float32}, py), convert(Vector{Float32}, pz), option)
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
