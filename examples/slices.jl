#!/usr/bin/env julia
# Rendering slices and an isosurface of MRI data.

import GR
const gr3 = GR.gr3

function draw(mesh::Cint; x::Union{Real, Void}=nothing, y::Union{Real, Void}=nothing, z::Union{Real, Void}=nothing)
    gr3.clear()
    gr3.drawmesh(mesh, 1, (0,0,0), (0,0,1), (0,1,0), (1,1,1), (1,1,1))
    gr3.drawslicemeshes(data, x=x, y=y, z=z)
    GR.clearws()
    gr3.drawimage(0, 1, 0, 1, 500, 500, gr3.DRAWABLE_GKS)
    GR.updatews()
end

data = open(stream -> read(stream, UInt16, (93, 64, 64)), "mri.raw")
data = min.(data, 2000) / 2000.0 * typemax(UInt16)
data = convert(Array{UInt16, 3}, floor.(data))
data = permutedims(data, [3, 2, 1])

GR.setviewport(0, 1, 0, 1)
gr3.cameralookat(-3, 2, -2, 0, 0, 0, 0, 0, -1)

mesh = gr3.createisosurfacemesh(data, (2.0/63, 2.0/63, 2.0/92), (-1.0, -1.0, -1.0), 40000)

GR.setcolormap(1)
for z in linspace(0, 1, 300)
    draw(mesh, x=0.9, z=z)
end
for y in linspace(1, 0.5, 300)
    draw(mesh, x=0.9, y=y, z=1)
end
GR.setcolormap(19)
for x in linspace(0.9, 0, 300)
    draw(mesh, x=x, y=0.5, z=1)
end
for x in linspace(0, 0.9, 300)
    draw(mesh, x=x, z=1)
end
gr3.terminate()
