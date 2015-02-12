#!/usr/bin/env julia
# -*- no-plot -*-

# Calculate Mandelbrot set using OpenCL

import OpenCL
const cl = OpenCL

import GR

const mandel_kernel = "
#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable
__kernel void mandelbrot(__global double2 *q, __global ushort *output,
                         double const min_x, double const max_x,
                         double const min_y, double const max_y,
                         ushort const width, ushort const height,
                         ushort const iters)
{
    int ci = 0, inc = 1;
    int gid = get_global_id(0);
    double nreal, real = 0;
    double imag = 0;

    q[gid].x = min_x + (gid % width) * (max_x - min_x) / width;
    q[gid].y = min_y + (gid / width) * (max_y - min_y) / height;

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
}"

for device in reverse(cl.available_devices(cl.platforms()[1]))
    global ctx, queue, prg

    ctx = cl.Context(device)
    queue = cl.CmdQueue(ctx)
    try
        prg = cl.Program(ctx, source = mandel_kernel) |> cl.build!
        println(device[:name])
        break
    end
end

function calc_fractal(q, min_x, max_x, min_y, max_y, width, height, iters)
    global ctx, queue, prg

    output = Array(Uint16, size(q))

    q_opencl = cl.Buffer(Complex128, ctx, (:r, :copy), hostbuf=q)
    output_opencl = cl.Buffer(Uint16, ctx, :w, length(output))

    k = cl.Kernel(prg, "mandelbrot")
    cl.call(queue, k, length(q), nothing, q_opencl, output_opencl,
            min_x, max_x, min_y, max_y, uint16(width), uint16(height), uint16(iters))
    cl.copy!(queue, output, output_opencl)

    return output
end

function create_fractal(min_x, max_x, min_y, max_y, width, height, iters)
    q = zeros(Complex128, (width, height))

    output = calc_fractal(q, min_x, max_x, min_y, max_y, width, height, iters)

    return output
end


x = -0.9223327810370947027656057193752719757635
y = 0.3102598350874576432708737495917724836010

f = 0.5
for i in 1:200
    tic()
    image = create_fractal(x-f, x+f, y-f, y+f, 500, 500, 400)
    dt = toq()

    @printf("Mandelbrot created in %f s\n", dt)

    GR.clearws()
    GR.setviewport(0, 1, 0, 1)
    GR.setcolormap(13)
    GR.cellarray(0, 1, 0, 1, 500, 500, image + 1000)
    GR.updatews()

    f *= 0.9
end
