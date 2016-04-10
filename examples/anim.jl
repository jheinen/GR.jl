# Compare line drawing performance of Matplotlib vs. GR
#
# These are the results on a MacBook Pro 2,6 GHz Intel Core i5::
#
#     fps (mpl):   27
#     fps  (GR):  775
#       speedup:   28.7

import PyPlot

x = collect(0:0.01:2*pi)

tic()
line, = PyPlot.plot(x, sin(x))
for i = 1:200
    line[:set_ydata](sin(x + i / 10.0))
    PyPlot.draw()
    PyPlot.pause(0.0001)
end

fps_mpl = round(200 / toq())
println("fps (mpl): ", fps_mpl)

import GR

tic()
for i = 1:200
    GR.plot(x, sin(x + i / 10.0))
    sleep(0.0001) # unnecessary
end

fps_gr = round(200 / toq())
println("fps  (GR): ", fps_gr)

println(@sprintf("  speedup: %6.1f",  float(fps_gr) / fps_mpl))
