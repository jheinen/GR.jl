# Compare line drawing performance of Matplotlib vs. GR
#
# The results depend strongly on which backend is used in GR and/or Matplotlib.
# Depending on the selection, however, improvements by a factor of 50 are possible.
# The best results can be achieved with the Qt driver (gksqt).
#
# The increase in drawing speed through the GR Matplotlib backend is comparatively
# small, since most of the time is spent in Matplotlib/Python.

ENV["JULIA_PYTHONCALL_EXE"] = "/usr/local/bin/python3"
ENV["GKSwstype"] = "gksqt"
ENV["MPLBACKEND"]="module://gr.matplotlib.backend_gr"

import PythonPlot
import GR

function mpl()
    x = collect(0:0.01:2*pi)

    PythonPlot.plot(x, sin.(x))
    PythonPlot.ion()
    t = time_ns()
    for i = 1:100
        PythonPlot.cla()
        PythonPlot.plot(x .+ i / 10.0, sin.(x .+ i / 10.0))
        if haskey(ENV, "MPLBACKEND")
           PythonPlot.show()
        else
           PythonPlot.pause(0.0001)
        end
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
