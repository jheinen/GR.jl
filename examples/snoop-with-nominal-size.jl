using Random
rng = MersenneTwister(1234)

using GR

mw, mh, w, h = inqdspsize()
mw *= 0.3      # 30%
mh = mw * 3/4  # aspect ratio 4:3

setnominalsize(0.5)

x = 0:π/100:2π
y = sin.(x)
plot(x, y, figsize=(mw, mh))

x = LinRange(0, 1, 51)
y = x .- x.^2
scatter(x, y, figsize=(mw, mh))

sz = LinRange(0.5, 3, length(x))
c = LinRange(0, 255, length(x))
scatter(x, y, sz, c, figsize=(mw, mh))

stem(x, y, figsize=(mw, mh))

histogram(randn(rng, 10000), figsize=(mw, mh))

plot(randn(rng, 50), figsize=(mw, mh))

oplot(randn(rng, 50, 3), figsize=(mw, mh))

x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
plot3(x, y, z, figsize=(mw, mh))

angles = LinRange(0, 2pi, 40)
radii = LinRange(0, 2, 40)
polar(angles, radii, figsize=(mw, mh))

x = 2 .* rand(rng, 100) .- 1
y = 2 .* rand(rng, 100) .- 1
z = 2 .* rand(rng, 100) .- 1
scatter3(x, y, z, figsize=(mw, mh))

c = 999 .* rand(rng, 100) .+ 1
scatter3(x, y, z, c, figsize=(mw, mh))

x = randn(rng, 100000)
y = randn(rng, 100000)
hexbin(x, y, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
contour(x, y, z, figsize=(mw, mh))

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
contour(x, y, z, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
contourf(x, y, z, figsize=(mw, mh))

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
contourf(x, y, z, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) + cos.(y)
tricont(x, y, z, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
surface(x, y, z, figsize=(mw, mh))

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
surface(x, y, z, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
trisurf(x, y, z, figsize=(mw, mh))

z = peaks()
surface(z, figsize=(mw, mh))

x = 8 .* rand(rng, 100) .- 4
y = 8 .* rand(rng, 100) .- 4
z = sin.(x) .+ cos.(y)
wireframe(x, y, z, figsize=(mw, mh))

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
wireframe(x, y, z, figsize=(mw, mh))

x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
heatmap(z, figsize=(mw, mh))

imshow(z, figsize=(mw, mh))

if !haskey(ENV, "GRDISPLAY")
    ρ = LinRange(0, 7, 200)
    θ = LinRange(0, 2π, 360)
    polarheatmap(θ, ρ, sin.(2ρ) .* cos.(θ'), figsize=(mw, mh))
end

s = LinRange(-1, 1, 40)
v = 1 .- (s .^ 2 .+ (s .^ 2)' .+ reshape(s, 1, 1, :) .^ 2) .^ 0.5
isosurface(v, isovalue=0.2, figsize=(mw, mh))

volume(randn(rng, 50, 50, 50), figsize=(mw, mh))

N = 1_000_000
x = randn(rng, N)
y = randn(rng, N)
shade(x, y, figsize=(mw, mh))

if !haskey(ENV, "GRDISPLAY")
    setprojectiontype(0)

    setwsviewport(0, mw, 0, mh)
    setwswindow(0, 1, 0, 3/4)

    clearws()
    xd = -2 .+ 4 * rand(rng, 100)
    yd = -2 .+ 4 * rand(rng, 100)
    zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

    setviewport(0.1, 0.95, 0.1, 0.7)
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

    x_axis = axis('X', tick=0.25, org=-2, major_count=2, tick_size=0.01)
    y_axis = axis('Y', tick=0.25, org=-2, major_count=2, tick_size=0.01)
    drawaxes(x_axis, y_axis, GR.AXES_SIMPLE_AXES)

    updatews()
end

