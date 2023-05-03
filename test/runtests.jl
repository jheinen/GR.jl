ENV["JULIA_DEBUG"] = "GR"

using Random
using Test
using GR

rng = MersenneTwister(1234)

mutable struct Example
    title::AbstractString
    code::Expr
end

const _examples = Example[

Example("Simple line plot", quote
    x = 0:π/100:2π
    y = sin.(x)
    plot(x, y)
end),
Example("Scatter plot", quote
    x = LinRange(0, 1, 51)
    y = x .- x.^2
    scatter(x, y)
end),

Example("Colored scatter plot", quote
    sz = LinRange(0.5, 3, length(x))
    c = LinRange(0, 255, length(x))
    scatter(x, y, sz, c)
end),

Example("Stem plot", quote
    stem(x, y)
end),

Example("Histogram plot", quote
    histogram(randn(rng, 10000))
end),

Example("Multi-line plot", quote
    plot(randn(rng, 50))
end),

Example("Overlay plot", quote
    oplot(randn(rng, 50, 3))
end),

Example("3-d line plot", quote
    x = LinRange(0, 30, 1000)
    y = cos.(x) .* x
    z = sin.(x) .* x
    plot3(x, y, z)
end),

Example("Polar plot", quote
    angles = LinRange(0, 2pi, 40)
    radii = LinRange(0, 2, 40)
    polar(angles, radii)
end),

Example("3-d point plot", quote
    x = 2 .* rand(rng, 100) .- 1
    y = 2 .* rand(rng, 100) .- 1
    z = 2 .* rand(rng, 100) .- 1
    scatter3(x, y, z)
end),

Example("Colored 3-d point plot", quote
    c = 999 .* rand(rng, 100) .+ 1
    scatter3(x, y, z, c)
end),

Example("Hexbin plot", quote
    x = randn(rng, 100000)
    y = randn(rng, 100000)
    hexbin(x, y)
end),

Example("Contour plot", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) .+ cos.(y)
    contour(x, y, z)
end),

Example("Contour plot of matrix", quote
    x = LinRange(-2, 2, 40)
    y = LinRange(0, pi, 20)
    z = sin.(x') .+ cos.(y)
    contour(x, y, z)
end),

Example("Filled contour plot", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) .+ cos.(y)
    contourf(x, y, z)
end),

Example("Filled contour plot of matrix", quote
    x = LinRange(-2, 2, 40)
    y = LinRange(0, pi, 20)
    z = sin.(x') .+ cos.(y)
    contourf(x, y, z)
end),

Example("Filled contour plot on a triangular mesh", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) + cos.(y)
    tricont(x, y, z)
end),

Example("Surface plot", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) .+ cos.(y)
    surface(x, y, z)
end),

Example("Surface plot of matrix", quote
    x = LinRange(-2, 2, 40)
    y = LinRange(0, pi, 20)
    z = sin.(x') .+ cos.(y)
    surface(x, y, z)
end),

Example("Surface plot on a triangular mesh", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) .+ cos.(y)
    trisurf(x, y, z)
end),

Example("Simple surface plot", quote
    z = peaks()
    surface(z)
end),

Example("Wireframe plot", quote
    x = 8 .* rand(rng, 100) .- 4
    y = 8 .* rand(rng, 100) .- 4
    z = sin.(x) .+ cos.(y)
    wireframe(x, y, z)
end),

Example("Wireframe plot of matrix", quote
    x = LinRange(-2, 2, 40)
    y = LinRange(0, pi, 20)
    z = sin.(x') .+ cos.(y)
    wireframe(x, y, z)
end),

Example("Heatmap plot", quote
    x = LinRange(-2, 2, 40)
    y = LinRange(0, pi, 20)
    z = sin.(x') .+ cos.(y)
    heatmap(z)
end),

Example("Image plot", quote
    imshow(z)
end),

Example("Polar heatmap plot", quote
    ρ = LinRange(0, 7, 200)
    θ = LinRange(0, 2π, 360)
    polarheatmap(θ, ρ, sin.(2ρ) .* cos.(θ'))
end),

Example("Isosurface plot", quote
    s = LinRange(-1, 1, 40)
    v = 1 .- (s .^ 2 .+ (s .^ 2)' .+ reshape(s, 1, 1, :) .^ 2) .^ 0.5
    isosurface(v, isovalue=0.2)
end),

Example("Volume plot", quote
    GR.GR3.terminate()
    volume(randn(rng, 50, 50, 50))
end),

Example("Shade points", quote
    N = 1_000_000
    x = randn(rng, N)
    y = randn(rng, N)
    shade(x, y)
end),

Example("Discrete plot", quote
    xd = -2 .+ 4 * rand(rng, 100)
    yd = -2 .+ 4 * rand(rng, 100)
    zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

    setprojectiontype(0)
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
end)
]

function basic_tests(title; wstype="nul", fig="")
    if wstype != "nul"
        file_path = tempname() * '.' * wstype
        ENV["GKS_WSTYPE"] = wstype
        ENV["GKS_FILEPATH"] = file_path
    elseif fig == ""
        delete!(ENV, "GKS_WSTYPE")
        delete!(ENV, "GKS_FILEPATH")
    end
    ENV["GR3_USE_SR"] = "true"

    @info("Testing $(title)")
    res = nothing
    ok = failed = 0
    for ex in _examples
        if fig != ""
            fn = tempname() * '.' * fig
        end
        try
            clearws()
            eval(ex.code)
            updatews()
            if fig != ""
                savefig(fn)
            end
            res = "\e[32mok\e[0m"
            ok += 1
        catch e
            res = "\e[31mfailed\e[0m"
            failed += 1
        end
        if fig != ""
            @test isfile(fn)
            @test filesize(fn) > 0
        end
        @info("Testing plot: $(ex.title) => $res")
    end
    @info("$ok tests passed. $failed tests failed.")

    emergencyclosegks()

    if wstype != "nul"
        @test isfile(file_path)
        @test filesize(file_path) > 0
    end
end

@timev basic_tests("interactive graphics")
@timev basic_tests("multi-page PDF", wstype="pdf")
@timev basic_tests("single-page PDF files", fig="pdf")
@timev basic_tests("SVG output", fig="svg")
@timev basic_tests("PNG images", fig="png")

GR.GRPreferences.Downloader.download(pwd(); force = true)
GR.GRPreferences.Downloader.download(joinpath(pwd(), "gr"); force = true)
readdir("gr") .|> println
GR.GRPreferences.Downloader.download(; force = true)
GR.GRPreferences.use_upstream_binary(; force = true)
GR.GRPreferences.diagnostics()
GR.GRPreferences.use_jll_binary(; force = true)
GR.GRPreferences.diagnostics()
