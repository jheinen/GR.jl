#!/usr/bin/env julia

import GR
const gr3 = GR.gr3

function draw(mesh::Cint)
    gr3.clear()
    gr3.drawmesh(mesh, 1, (0,0,0), (0,0,1), (0,1,0), (1,1,1), (1,1,1))
    GR.clearws()
    gr3.drawimage(0, 1, 0, 1, 500, 500, gr3.DRAWABLE_GKS)
    GR.updatews()
end

data = open(stream -> read!(stream, Array{UInt16}(undef, 93, 64, 64)), "mri.raw")
data = min.(data, 2000) / 2000.0 * typemax(UInt16)
data = convert(Array{UInt16, 3}, floor.(data))
data = permutedims(data, [3, 2, 1])

GR.setviewport(0, 1, 0, 1)
gr3.cameralookat(-3, 2, -2, 0, 0, 0, 0, 0, -1)

mesh = gr3.createisosurfacemesh(data, (2.0/63, 2.0/63, 2.0/92), (-1.0, -1.0, -1.0), 40000)

GR.setcolormap(1)

gr3.setlightsources(2, [0, -1, 1, 1, -1, 1], [0.45, 0.7, 0.9, 0.93, 0.91, 0.2])
directions, colors = gr3.getlightsources(2)
@show directions, colors

draw(mesh)
