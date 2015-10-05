#!/usr/bin/env julia

import GR

function mandel(x, y, iters)
    c = complex(x, y)
    z = 0.0im
    ci = 0
    inc = 1

    for i in 0:iters
        z = z^2 + c
        if abs2(z) >= 4
            return ci
        end
        ci += inc
        if ci == 0 || ci == 255
            inc = -inc
        end
    end

    return 255
end

function create_fractal(min_x, max_x, min_y, max_y, image, iters)
    height = size(image, 1)
    width = size(image, 2)

    pixel_size_x = (max_x - min_x) / width
    pixel_size_y = (max_y - min_y) / height
    for x in 1:width
        real = min_x + (x - 1) * pixel_size_x
        for y in 1:height
            imag = min_y + (y - 1) * pixel_size_y
            color = mandel(real, imag, iters)
            image[y, x] = color
        end
    end
end

x = -0.9223327810370947027656057193752719757635
y = 0.3102598350874576432708737495917724836010

f = 0.5
for i in 0:200
    tic()
    image = zeros(Int32, 500, 500)
    create_fractal(x-f, x+f, y-f, y+f, image, 400)
    dt = toq()

    println(@sprintf("Mandelbrot created in %f s", dt))

    GR.clearws()
    GR.setviewport(0, 1, 0, 1)
    GR.setcolormap(13)
    GR.cellarray(0, 1, 0, 1, 500, 500, image + 1000)
    GR.updatews()

    f *= 0.9
end
