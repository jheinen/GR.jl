using Random
rng = MersenneTwister(1234)

using GR

x = 0:π/100:2π
y = sin.(x)
plot(x, y)

x = LinRange(0, 1, 51)
y = x .- x.^2
scatter(x, y)

sz = LinRange(0.5, 3, length(x))
c = LinRange(0, 255, length(x))
scatter(x, y, sz, c)

stem(x, y)

histogram(randn(rng, 10000))

plot(randn(rng, 50))

oplot(randn(rng, 50, 3))

x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
plot3(x, y, z)

angles = LinRange(0, 2pi, 40)
radii = LinRange(0, 2, 40)
polar(angles, radii)

x = 2 .* rand(rng, 100) .- 1
y = 2 .* rand(rng, 100) .- 1
z = 2 .* rand(rng, 100) .- 1
scatter3(x, y, z)

c = 999 .* rand(rng, 100) .+ 1
scatter3(x, y, z, c)

x = randn(rng, 100000)
y = randn(rng, 100000)
hexbin(x, y)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
contour(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
contour(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
contourf(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
contourf(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) + cos.(y)
tricont(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
surface(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
surface(x, y, z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
trisurf(x, y, z)

z = peaks()
surface(z)

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
wireframe(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
wireframe(x, y, z)

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
heatmap(z)

imshow(z)

if !haskey(ENV, "GRDISPLAY")
    ρ = LinRange(0, 7, 200)
    θ = LinRange(0, 2π, 360)
    polarheatmap(θ, ρ, sin.(2ρ) .* cos.(θ'))
end

s = LinRange(-1, 1, 40)
v = 1 .- (s .^ 2 .+ (s .^ 2)' .+ reshape(s, 1, 1, :) .^ 2) .^ 0.5
isosurface(v, isovalue=0.2)

volume(randn(rng, 50, 50, 50))

N = 1_000_000
x = randn(rng, N)
y = randn(rng, N)
shade(x, y)

if !haskey(ENV, "GRDISPLAY")
    setprojectiontype(0)

    clearws()
    xd = -2 .+ 4 * rand(rng, 100)
    yd = -2 .+ 4 * rand(rng, 100)
    zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

    setwsviewport(0, 0.1, 0, 0.1)
    setwswindow(0, 1, 0, 1)

    setviewport(0.1, 0.95, 0.1, 0.95)
    setwindow(-2, 2, -2, 2)
    setspace(-0.5, 0.5, 0, 90)

    setcolormap(0)
    setlinecolorind(1)
    setmarkersize(1)
    setmarkertype(-1)
    setmarkercolorind(1)
    setcharheight(0.024)
    settextalign(2, 0)
    settextfontprec(3, 0)

    x, y, z = gridit(xd, yd, zd, 200, 200)
    h = -0.5:0.05:0.5
    surface(x, y, z, 5)
    contour(x, y, h, z, 0)
    polymarker(xd, yd)
    GR.axes(0.25, 0.25, -2, -2, 2, 2, 0.01)

    updatews()
end
