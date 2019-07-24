using Distributions

function dists(specs; N=50)
  X = Float64[]
  Y = Float64[]
  for (x, y, σ) in specs
    xd = rand(Normal(x, σ), N)
    yd = rand(Normal(y, σ), N)
    append!(X, xd)
    append!(Y, yd)
  end
  X, Y
end

N = 1000000
x, y = dists([(2,2,0.02), (2,-2,0.1), (-2,-2,0.5), (-2,2,1.0), (0,0,3.0)], N=N)

println("# of points: ", length(x))

using GR

setviewport(0.1, 0.95, 0.1, 0.95)
setwindow(-10, 10, -10, 10)
setcharheight(0.02)
axes2d(0.5, 0.5, -10, -10, 4, 4, -0.005)
setcolormap(GR.COLORMAP_HOT)

@time shadepoints(x, y, xform=GR.XFORM_EQUALIZED)

updatews()

