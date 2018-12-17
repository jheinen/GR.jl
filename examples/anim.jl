# Compare line drawing performance of Matplotlib vs. GR
#
# These are the results on a MacBook Pro 2,6 GHz Intel Core i5::
#
# MPL:   10 fps  GR: 1400 fps  => speedup:  140.0

import PyPlot
import GR
ENV["GKSwstype"] = "gksqt"

function mpl()
    x = collect(0:0.01:2*pi)

    PyPlot.plot(x, sin.(x))
    t = time_ns()
    for i = 1:100
        PyPlot.cla()
        PyPlot.plot(x .+ i / 10.0, sin.(x .+ i / 10.0))
        PyPlot.pause(0.0001)
    end

    fps = round(Int64, 100 / (1e-9 * (time_ns() - t)))
end

function gr()
    x = collect(0:0.01:2*pi)

    GR.plot(x, sin.(x))
    t = time_ns()
    for i = 1:100
        GR.plot(x .+ i / 10.0, sin.(x .+ i / 10.0))
    end

    fps = round(Int64, 100 / (1e-9 * (time_ns() - t)))
end

using Printf

for i in 1:10
    fps_mpl = mpl()
    fps_gr = gr()
    speedup = float(fps_gr) / fps_mpl

    @printf("MPL: %4d fps  GR: %4d fps  => speedup: %6.1f\r",
            fps_mpl, fps_gr, speedup)
end

@printf("\n")
