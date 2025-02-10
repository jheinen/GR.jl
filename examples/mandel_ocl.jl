#!/usr/bin/env julia

# Calculate Mandelbrot set using OpenCL

using OpenCL
using pocl_jll

import GR

mandel_source = "
__kernel void mandelbrot(__global double2 *q,
                         __global ushort *output,
                         double const minX, double const maxX,
                         double const minY, double const maxY,
                         ushort const w, ushort const h,
                         ushort const iters)
{
    int ci = 0, inc = 1;
    int gid = get_global_id(0);
    double nreal, real = 0;
    double imag = 0;

    q[gid].x = minX + (gid % w) * (maxX - minX) / w;
    q[gid].y = minY + (gid / w) * (maxY - minY) / h;

    output[gid] = iters;

    for (int curiter = 0; curiter < iters; curiter++) {
        nreal = real * real - imag * imag + q[gid].x;
        imag = 2 * real * imag + q[gid].y;
        real = nreal;

        if (real * real + imag * imag >= 4) {
            output[gid] = ci;
            return;
        }
        ci += inc;
        if (ci == 0 || ci == 255)
            inc = -inc;
    }
}";

function mandel_opencl(q::Array{ComplexF64}, minX::Float64, maxX::Float64, minY::Float64, maxY::Float64, w, h, iters)
    q = CLArray(q)
    o = CLArray{Cushort}(undef, size(q))

    prg = cl.Program(source=mandel_source) |> cl.build!
    k = cl.Kernel(prg, "mandelbrot")

    clcall(k, Tuple{Ptr{ComplexF64}, Ptr{Cushort}, Float64, Float64, Float64, Float64, Cushort, Cushort, Cushort},
           q, o, minX, maxX, minY, maxY, w, h, iters; global_size=length(q))

    return Array(o)
end

x = -0.9223327810370947027656057193752719757635
y = 0.3102598350874576432708737495917724836010

GR.setviewport(0, 1, 0, 1)
GR.setcolormap(13)

for i in 1:200

    f = 0.5 * 0.9^i
    q = zeros(ComplexF64, (500, 500))
    dt = @elapsed image = mandel_opencl(q, x-f, x+f, y-f, y+f, 500, 500, 400)
    println("Mandelbrot created in $dt s")

    GR.clearws()
    GR.cellarray(0, 1, 0, 1, 500, 500, image .+ 1000)
    GR.updatews()

end
