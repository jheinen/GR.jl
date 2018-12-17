# Compare line drawing performance of Matplotlib vs. GR
#
# These are the results on a MacBook Pro 2,6 GHz Intel Core i5::
#
#     fps (mpl):   27
#     fps  (GR):  775
#       speedup:   28.7

import PyPlot

x = collect(0:0.01:2*pi)

line, = PyPlot.plot(x, sin.(x))
t = time_ns()
for i = 1:100
    line[:set_ydata](sin.(x .+ i / 10.0))
    PyPlot.draw()
    PyPlot.pause(0.0001)
end

fps_mpl = round(100 / (1e-9 * (time_ns() - t)))
println("fps (mpl): ", fps_mpl)

import GR

GR.plot(x, sin.(x))
t = time_ns()
for i = 1:100
    GR.plot(x, sin.(x .+ i / 10.0))
    sleep(0.0001) # unnecessary
end

fps_gr = round(100 / (1e-9 * (time_ns() - t)))
println("fps  (GR): ", fps_gr)

using Printf
println(@sprintf("  speedup: %6.1f",  float(fps_gr) / fps_mpl))
