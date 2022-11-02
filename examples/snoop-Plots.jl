using Random
rng = MersenneTwister(1234)

import Plots
const GR = Plots.GR

x = 0:π/100:2π
y = sin.(x)
GR.plot(x, y)

x = LinRange(0, 1, 51)
y = x .- x.^2
GR.scatter(x, y)

sz = LinRange(0.5, 3, length(x))
c = LinRange(0, 255, length(x))
GR.scatter(x, y, sz, c)

GR.stem(x, y)

GR.histogram(randn(rng, 10000))

GR.plot(randn(rng, 50))

GR.oplot(randn(rng, 50, 3))

x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
GR.plot3(x, y, z)

angles = LinRange(0, 2pi, 40)
radii = LinRange(0, 2, 40)
GR.polar(angles, radii)

x = 2 .* rand(rng, 100) .- 1
y = 2 .* rand(rng, 100) .- 1
z = 2 .* rand(rng, 100) .- 1
GR.scatter3(x, y, z)

c = 999 .* rand(rng, 100) .+ 1
GR.scatter3(x, y, z, c)

x = randn(rng, 100000)
y = randn(rng, 100000)
GR.hexbin(x, y)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
GR.contour(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
GR.contour(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
GR.contourf(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
GR.contourf(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) + cos.(y)
GR.tricont(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
GR.surface(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
GR.surface(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
GR.trisurf(x, y, z)

z = GR.peaks()
GR.surface(z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
GR.wireframe(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
GR.heatmap(z)

GR.imshow(z)

s = LinRange(-1, 1, 40)
v = 1 .- (s .^ 2 .+ (s .^ 2)' .+ reshape(s,1,1,:) .^ 2) .^ 0.5
GR.isosurface(v, isovalue=0.2)

GR.GR3.terminate()

GR.volume(randn(rng, 50, 50, 50))

N = 1_000_000
x = randn(rng, N)
y = randn(rng, N)
GR.shade(x, y)

GR.setprojectiontype(0)

GR.clearws()
xd = -2 .+ 4 * rand(rng, 100)
yd = -2 .+ 4 * rand(rng, 100)
zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

GR.setviewport(0.1, 0.95, 0.1, 0.70)
GR.setwindow(-2, 2, -2, 2)
GR.setspace(-0.5, 0.5, 0, 90)
GR.setcolormap(0)
GR.setlinecolorind(1)
GR.setmarkersize(1)
GR.setmarkertype(-1)
GR.setmarkercolorind(1)
GR.setcharheight(0.024)
GR.settextalign(2, 0)
GR.settextfontprec(3, 0)

x, y, z = GR.gridit(xd, yd, zd, 200, 200)
h = -0.5:0.05:0.5
GR.surface(x, y, z, 5)
GR.contour(x, y, h, z, 0)
GR.polymarker(xd, yd)
GR.axes(0.25, 0.25, -2, -2, 2, 2, 0.01)

GR.updatews()

sleep(3)

GR.emergencyclosegks()

Plots.gr(show=true)

x = 1:10; y = rand(rng, 10);
Plots.plot(x,y)

Plots.scatter(x,y)

Plots.histogram(randn(rng, 10000))

z = GR.peaks();
Plots.surface(z)

Plots.contour(z)

x = LinRange(0, 30, 1000); y = cos.(x) .* x; z = sin.(x) .* x
Plots.plot3d(x, y, z)

import StatsPlots
y = rand(rng, 100, 4)
StatsPlots.violin(["Series 1" "Series 2" "Series 3" "Series 4"], y, leg = false)

StatsPlots.boxplot!(["Series 1" "Series 2" "Series 3" "Series 4"], y, leg = false)

sleep(3)
