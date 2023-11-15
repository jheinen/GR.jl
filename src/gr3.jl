module GR3

import GR
import Libdl

macro triplet(t)
    :( Tuple{$t, $t, $t} )
end

macro ArrayToVector(ctype, data)
    return :( convert(Vector{$(esc(ctype))}, vec($(esc(data)))) )
end

mutable struct PNG s::Array{UInt8} end
mutable struct HTML s::AbstractString end

Base.show(io::IO, ::MIME"image/png", x::PNG) = write(io, x.s)
Base.show(io::IO, ::MIME"text/html", x::HTML) = print(io, x.s)

function _readfile(path)
    data = Array(UInt8, filesize(path))
    s = open(path, "r")
    read!(s, data)
end

mutable struct GR3Exception <: Exception
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
  error_code = ccall(GR.libGR3_ptr(:gr3_geterror), Int32, (Int32, Ptr{Cint}, Ptr{Ptr{UInt8}}), 1, line, file)
  if (error_code != 0)
    line = line[1]
    file = unsafe_string(file[1])
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
  ccall(GR.libGR3_ptr(:gr3_init), Int32, (Ptr{Int}, ), attrib_list)
  _check_error()
end
export init

function free(pointer)
  ccall(GR.libGR3_ptr(:gr3_free), Nothing, (Ptr{Nothing}, ), pointer)
  _check_error()
end
export free

function terminate()
  ccall(GR.libGR3_ptr(:gr3_terminate), Nothing, ())
  _check_error()
end
export terminate

function useframebuffer(framebuffer)
  ccall(GR.libGR3_ptr(:gr3_useframebuffer), Nothing, (UInt32, ), framebuffer)
  _check_error()
end
export useframebuffer

function usecurrentframebuffer()
  ccall(GR.libGR3_ptr(:gr3_usecurrentframebuffer), Nothing, ())
  _check_error()
end
export usecurrentframebuffer

function getimage(width, height, use_alpha=true)
  bpp = use_alpha ? 4 : 3
  bitmap = zeros(UInt8, width * height * bpp)
  ccall(GR.libGR3_ptr(:gr3_getimage),
        Int32,
        (Int32, Int32, Int32, Ptr{UInt8}),
        width, height, use_alpha, bitmap)
  _check_error()
  return bitmap
end
export getimage

function save(filename, width, height)
  ccall(GR.libGR3_ptr(:gr3_export),
        Int32,
        (Ptr{Cchar}, Int32, Int32),
        filename, width, height)
  _check_error()
  ext = splitext(filename)[end:end][1]
  if ext == ".png"
    content = PNG(_readfile(filename))
  elseif ext == ".html"
    content = HTML("<iframe src=\"files/$filename\" width=$width height=$height></iframe>")
  else
    content = nothing
  end
  return content
end
export save

function getrenderpathstring()
  val = ccall(GR.libGR3_ptr(:gr3_getrenderpathstring),
              Ptr{UInt8}, (), )
  _check_error()
  unsafe_string(val)
end
export getrenderpathstring

function drawimage(xmin, xmax, ymin, ymax, pixel_width, pixel_height, window)
  ccall(GR.libGR3_ptr(:gr3_drawimage),
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
  ccall(GR.libGR3_ptr(:gr3_createmesh),
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
  ccall(GR.libGR3_ptr(:gr3_createindexedmesh),
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
  ccall(GR.libGR3_ptr(:gr3_drawmesh),
        Nothing,
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
    ccall(GR.libGR3_ptr(:gr3_createheightmapmesh),
          Nothing,
          (Ptr{Float32}, Int32, Int32),
          @ArrayToVector(Float32, heightmap), num_columns, num_rows)
    _check_error()
  else
    error("Array has incorrect length or dimension.")
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
    ccall(GR.libGR3_ptr(:gr3_drawheightmap),
          Nothing,
          (Ptr{Float32}, Int32, Int32, Ptr{Float32}, Ptr{Float32}),
          @ArrayToVector(Float32, heightmap), num_columns, num_rows, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _scales))
    _check_error()
  else
    error("Array has incorrect length or dimension.")
  end
end
export drawheightmap

function deletemesh(mesh)
  ccall(GR.libGR3_ptr(:gr3_deletemesh), Nothing, (Int32, ), mesh)
  _check_error()
end
export deletemesh

function setquality(quality)
  ccall(GR.libGR3_ptr(:gr3_setquality), Nothing, (Int32, ), quality)
  _check_error()
end
export setquality

function clear()
  ccall(GR.libGR3_ptr(:gr3_clear), Nothing, ())
  _check_error()
end
export clear

function cameralookat(camera_x, camera_y, camera_z,
                      center_x, center_y, center_z,
                      up_x, up_y, up_z)
  ccall(GR.libGR3_ptr(:gr3_cameralookat),
        Nothing,
        (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32),
        camera_x, camera_y, camera_z, center_x, center_y, center_z, up_x, up_y, up_z)
  _check_error()
end
export cameralookat

function setcameraprojectionparameters(vertical_field_of_view, zNear, zFar)
  ccall(GR.libGR3_ptr(:gr3_setcameraprojectionparameters),
        Nothing,
        (Float32, Float32, Float32),
        vertical_field_of_view, zNear, zFar)
  _check_error()
end
export setcameraprojectionparameters

function setlightdirection(x, y, z)
  ccall(GR.libGR3_ptr(:gr3_setlightdirection),
        Nothing,
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
  ccall(GR.libGR3_ptr(:gr3_drawcylindermesh),
        Nothing,
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
  ccall(GR.libGR3_ptr(:gr3_drawconemesh),
        Nothing,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _radii), @ArrayToVector(Float32, _lengths))
  _check_error()
end
export drawconemesh

function drawspheremesh(n, positions, colors, radii)
  _positions = [ Float32(x) for x in positions ]
  _colors = [ Float32(x) for x in colors ]
  _radii = [ Float32(x) for x in radii ]
  ccall(GR.libGR3_ptr(:gr3_drawspheremesh),
        Nothing,
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
  ccall(GR.libGR3_ptr(:gr3_drawcubemesh),
        Nothing,
        (Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        n, @ArrayToVector(Float32, _positions), @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _ups), @ArrayToVector(Float32, _colors), @ArrayToVector(Float32, _scales))
  _check_error()
end
export drawcubemesh

function setbackgroundcolor(red, green, blue, alpha)
  ccall(GR.libGR3_ptr(:gr3_setbackgroundcolor),
        Nothing,
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
  err = ccall(GR.libGR3_ptr(:gr3_createisosurfacemesh),
              Int32,
              (Ptr{Cint}, Ptr{UInt16}, UInt16, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, Float64, Float64, Float64, Float64, Float64, Float64),
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
  elseif ndims(px) == ndims(py) == ndims(pz) == 2
    nx, ny = size(pz)
    out_of_bounds = size(px)[1] != ny || size(px)[2] != nx ||
                    size(py)[1] != ny || size(py)[2] != nx
  elseif ndims(pz) == 2
    out_of_bounds = size(pz)[1] != nx || size(pz)[2] != ny
  else
    out_of_bounds = true
  end
  if !out_of_bounds
    if option != GR.OPTION_3D_MESH
      if ndims(pz) == 2
        pz = reshape(pz, nx * ny)
      end
      _px = [ Float32(x) for x in px ]
      _py = [ Float32(y) for y in py ]
      _pz = [ Float32(z) for z in pz ]
    else
      _px = px'
      _py = py'
      _pz = pz
    end
    ccall(GR.libGR3_ptr(:gr3_surface),
          Nothing,
          (Int32, Int32, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Int32),
          nx, ny, @ArrayToVector(Float32, _px), @ArrayToVector(Float32, _py), @ArrayToVector(Float32, _pz), option)
    _check_error()
  else
    error("Arrays have incorrect length or dimension.")
  end
end

function setlightparameters(ambient, diffuse, specular, specular_power)
  ccall(GR.libGR3_ptr(:gr3_setlightparameters),
        Nothing,
        (Float32, Float32, Float32, Float32),
        ambient, diffuse, specular, specular_power)
  _check_error()
end

function getlightparameters()
  ambient = Cfloat[1]
  diffuse = Cfloat[1]
  specular = Cfloat[1]
  specular_power = Cfloat[1]
  ccall(GR.libGR3_ptr(:gr3_getlightparameters),
        Nothing,
        (Ptr{Float32}, Ptr{Float32}, Ptr{Float32}, Ptr{Float32}),
        ambient, diffuse, specular, specular_power)
  _check_error()
  return ambient[1], diffuse[1], specular[1], specular_power[1]
end

function isosurface(data::Array{Float64,3}, iso::Float64, color)
  _data = [ Float32(value) for value in data ]
  nx, ny, nz = size(data)
  _color = [ Float32(value) for value in color ]
  ccall(GR.libGR3_ptr(:gr3_isosurface),
        Nothing,
        (Int32, Int32, Int32, Ptr{Float32}, Float32, Ptr{Float32}, Ptr{Int32}),
        nx, ny, nz, @ArrayToVector(Float32, _data), Float32(iso), @ArrayToVector(Float32, _color), C_NULL)
  _check_error()
end

function volume(data::Array{Float64,3}, algorithm::Int64)
  dmin = Cdouble[-1]
  dmax = Cdouble[-1]
  nx, ny, nz = size(data)
  data = reshape(data, nx * ny * nz)
  ccall(GR.libGR3_ptr(:gr_volume),
        Nothing,
        (Cint, Cint, Cint, Ptr{Cdouble}, Cint, Ptr{Cdouble}, Ptr{Cdouble}),
        nx, ny, nz, data, algorithm, dmin, dmax)
  return dmin[1], dmax[1]
end

function createslicemeshes(grid; x::Union{Real, Nothing}=nothing, y::Union{Real, Nothing}=nothing, z::Union{Real, Nothing}=nothing, step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing)
    if x === nothing && y === nothing && z === nothing
        x = 0.5
        y = 0.5
        z = 0.5
    end
    if typeof(grid[1,1,1]) <: Unsigned
        input_max = typemax(typeof(grid[1,1,1]))
    elseif typeof(grid[1,1,1]) <: Real
        input_max = convert(typeof(grid[1,1,1]), 1.0)
        grid = min.(grid, input_max)
    else
        error("grid must be three dimensional array of Real numbers")
        return(nothing)
    end
    scaling_factor = typemax(UInt16) / input_max
    grid = Array{UInt16, 3}(floor.(grid * scaling_factor))
    nx, ny, nz = size(grid)
    if step === nothing && offset === nothing
        step = (2.0/(nx-1), 2.0/(ny-1), 2.0/(nz-1))
        offset = (-1.0, -1.0, -1.0)
    elseif offset === nothing
        offset = (-step[1] * (nx-1) / 2.0,
                  -step[2] * (ny-1) / 2.0,
                  -step[3] * (nz-1) / 2.0)
    elseif step === nothing
        step = (-offset[1] * 2.0 / (nx-1),
                -offset[2] * 2.0 / (ny-1),
                -offset[3] * 2.0 / (nz-1))
    end
    stride_x, stride_y, stride_z = 1, nx, nx*ny
    dim_x, dim_y, dim_z = convert(Tuple{UInt32, UInt32, UInt32}, size(grid))
    step_x, step_y, step_z = convert(Tuple{Float64, Float64, Float64}, step)
    offset_x, offset_y, offset_z = convert(Tuple{Float64, Float64, Float64}, offset)

    if x !== nothing
        x = convert(UInt32, floor(clamp(x, 0, 1) * nx))
        mesh = Cint[0]
        ccall(GR.libGR3_ptr(:gr3_createxslicemesh),
            Nothing,
            (Ptr{UInt32}, Ptr{UInt16}, UInt32,
            UInt32, UInt32, UInt32,
            UInt32, UInt32, UInt32,
            Float64, Float64, Float64,
            Float64, Float64, Float64),
            mesh, grid, x,
            dim_x, dim_y, dim_z,
            stride_x, stride_y, stride_z,
            step_x, step_y, step_z,
            offset_x, offset_y, offset_z)
        _check_error()
        _mesh_x = mesh[1]
    else
        _mesh_x = nothing
    end

    if y !== nothing
        y = convert(UInt32, floor(clamp(y, 0, 1) * ny))
        mesh = Cint[0]
        ccall(GR.libGR3_ptr(:gr3_createyslicemesh),
            Nothing,
            (Ptr{UInt32}, Ptr{UInt16}, UInt32,
            UInt32, UInt32, UInt32,
            UInt32, UInt32, UInt32,
            Float64, Float64, Float64,
            Float64, Float64, Float64),
            mesh, grid, y,
            dim_x, dim_y, dim_z,
            stride_x, stride_y, stride_z,
            step_x, step_y, step_z,
            offset_x, offset_y, offset_z)
        _check_error()
        _mesh_y = mesh[1]
    else
        _mesh_y = nothing
    end

    if z !== nothing
        z = convert(UInt32, floor(clamp(z, 0, 1) * nz))
        mesh = Cint[0]
        ccall(GR.libGR3_ptr(:gr3_createzslicemesh),
            Nothing,
            (Ptr{UInt32}, Ptr{UInt16}, UInt32,
            UInt32, UInt32, UInt32,
            UInt32, UInt32, UInt32,
            Float64, Float64, Float64,
            Float64, Float64, Float64),
            mesh, grid, z,
            dim_x, dim_y, dim_z,
            stride_x, stride_y, stride_z,
            step_x, step_y, step_z,
            offset_x, offset_y, offset_z)
        _check_error()
        _mesh_z = mesh[1]
    else
        _mesh_z = nothing
    end

    return(_mesh_x, _mesh_y, _mesh_z)
end
export createslicemeshes

function createxslicemesh(grid, x::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing)
    return createslicemeshes(grid, x=x, step=step, offset=offset)[1]
end
export createxslicemesh

function createyslicemesh(grid, y::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing)
    return createslicemeshes(grid, y=y, step=step, offset=offset)[2]
end
export createyslicemesh

function createzslicemesh(grid, z::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing)
    return createslicemeshes(grid, z=z, step=step, offset=offset)[3]
end
export createzslicemesh

function drawxslicemesh(grid, x::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing, position::Tuple{Real, Real, Real}=(0, 0, 0), direction::Tuple{Real, Real, Real}=(0, 0, 1), up::Tuple{Real, Real, Real}=(0, 1, 0), color::Tuple{Real, Real, Real}=(1, 1, 1), scale::Tuple{Real, Real, Real}=(1, 1, 1))
    mesh = createxslicemesh(grid, x, step=step, offset=offset)
    drawmesh(mesh, 1, position, direction, up, color, scale)
    deletemesh(mesh)
end
export drawxslicemesh

function drawyslicemesh(grid, y::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing, position::Tuple{Real, Real, Real}=(0, 0, 0), direction::Tuple{Real, Real, Real}=(0, 0, 1), up::Tuple{Real, Real, Real}=(0, 1, 0), color::Tuple{Real, Real, Real}=(1, 1, 1), scale::Tuple{Real, Real, Real}=(1, 1, 1))
    mesh = createxslicemesh(grid, y, step=step, offset=offset)
    drawmesh(mesh, 1, position, direction, up, color, scale)
    deletemesh(mesh)
end
export drawyslicemesh

function drawzslicemesh(grid, z::Real=0.5; step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing, position::Tuple{Real, Real, Real}=(0, 0, 0), direction::Tuple{Real, Real, Real}=(0, 0, 1), up::Tuple{Real, Real, Real}=(0, 1, 0), color::Tuple{Real, Real, Real}=(1, 1, 1), scale::Tuple{Real, Real, Real}=(1, 1, 1))
    mesh = createxslicemesh(grid, z, step=step, offset=offset)
    drawmesh(mesh, 1, position, direction, up, color, scale)
    deletemesh(mesh)
end
export drawzslicemesh

function drawslicemeshes(data; x::Union{Real, Nothing}=nothing, y::Union{Real, Nothing}=nothing, z::Union{Real, Nothing}=nothing, step::Union{Tuple{Real, Real, Real}, Nothing}=nothing, offset::Union{Tuple{Real, Real, Real}, Nothing}=nothing, position::Tuple{Real, Real, Real}=(0, 0, 0), direction::Tuple{Real, Real, Real}=(0, 0, 1), up::Tuple{Real, Real, Real}=(0, 1, 0), color::Tuple{Real, Real, Real}=(1, 1, 1), scale::Tuple{Real, Real, Real}=(1, 1, 1))
    meshes = createslicemeshes(data, x=x, y=y, z=z, step=step, offset=offset)
    for mesh in meshes
        if mesh !== nothing
            drawmesh(mesh, 1, position, direction, up, color, scale)
            deletemesh(mesh)
        end
    end
end
export drawslicemeshes

function setlightsources(num_lights, directions, colors)
  @assert length(directions) == length(colors)
  _directions = [ Float32(x) for x in directions ]
  _colors = [ Float32(x) for x in colors ]
  ccall(GR.libGR3_ptr(:gr3_setlightsources),
        Nothing,
        (Int32, Ptr{Float32}, Ptr{Float32}),
        num_lights, @ArrayToVector(Float32, _directions), @ArrayToVector(Float32, _colors))
end
export setlightsources

function getlightsources(num_lights)
  directions = Vector{Cfloat}(undef, num_lights * 3)
  colors = Vector{Cfloat}(undef, num_lights * 3)
  ccall(GR.libGR3_ptr(:gr3_getlightsources),
        Nothing,
        (Int32, Ptr{Cfloat}, Ptr{Cfloat}),
        num_lights, directions, colors)
  return directions, colors
end
export getlightsources

const IA_END_OF_LIST = 0
const IA_FRAMEBUFFER_WIDTH = 1
const IA_FRAMEBUFFER_HEIGHT = 2

const ERROR_NONE = 0
const ERROR_INVALID_VALUE = 1
const ERROR_INVALID_ATTRIBUTE = 2
const ERROR_INIT_FAILED = 3
const ERROR_OPENGL_ERR = 4
const ERROR_OUT_OF_MEM = 5
const ERROR_NOT_INITIALIZED = 6
const ERROR_CAMERA_NOT_INITIALIZED = 7
const ERROR_UNKNOWN_FILE_EXTENSION = 8
const ERROR_CANNOT_OPEN_FILE = 9
const ERROR_EXPORT = 10

const QUALITY_OPENGL_NO_SSAA  = 0
const QUALITY_OPENGL_2X_SSAA  = 2
const QUALITY_OPENGL_4X_SSAA  = 4
const QUALITY_OPENGL_8X_SSAA  = 8
const QUALITY_OPENGL_16X_SSAA = 16
const QUALITY_POVRAY_NO_SSAA  = 0+1
const QUALITY_POVRAY_2X_SSAA  = 2+1
const QUALITY_POVRAY_4X_SSAA  = 4+1
const QUALITY_POVRAY_8X_SSAA  = 8+1
const QUALITY_POVRAY_16X_SSAA = 16+1

const DRAWABLE_OPENGL = 1
const DRAWABLE_GKS = 2

const SURFACE_DEFAULT     =  0
const SURFACE_NORMALS     =  1
const SURFACE_FLAT        =  2
const SURFACE_GRTRANSFORM =  4
const SURFACE_GRCOLOR     =  8
const SURFACE_GRZSHADED   = 16

end # module
