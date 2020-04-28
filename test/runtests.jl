using Test

using Random
rng = MersenneTwister(1234)

using GR
GR.__init__()

mutable struct Example
  title::AbstractString
  code::Vector{Expr}
end

const _examples = Example[

Example("Simple line plot", [:(begin
        x = 0:π/100:2π
        y = sin.(x)
        plot(x, y)
    end)]),
Example("Scatter plot", [:(begin
        x = LinRange(0, 1, 51)
        y = x .- x.^2
        scatter(x, y)
    end)]),

Example("Colored scatter plot", [:(begin
        sz = LinRange(50, 300, length(x))
        c = LinRange(0, 255, length(x))
        scatter(x, y, sz, c)
    end)]),

Example("Stem plot", [:(begin
        stem(x, y)
    end)]),

Example("Histogram plot", [:(begin
        histogram(randn(rng, 10000))
    end)]),

Example("Multi-line plot", [:(begin
        plot(randn(rng, 50))
    end)]),

Example("Overlay plot", [:(begin
        oplot(randn(rng, 50, 3))
    end)]),

Example("3-d line plot", [:(begin
        x = LinRange(0, 30, 1000)
        y = cos.(x) .* x
        z = sin.(x) .* x
        plot3(x, y, z)
    end)]),

Example("Polar plot", [:(begin
        angles = LinRange(0, 2pi, 40)
        radii = LinRange(0, 2, 40)
        polar(angles, radii)
    end)]),

Example("3-d point plot", [:(begin
        x = 2 .* rand(rng, 100) .- 1
        y = 2 .* rand(rng, 100) .- 1
        z = 2 .* rand(rng, 100) .- 1
        scatter3(x, y, z)
    end)]),

Example("Colored 3-d point plot", [:(begin
        c = 999 .* rand(rng, 100) .+ 1
        scatter3(x, y, z, c)
    end)]),

Example("Hexbin plot", [:(begin
        x = randn(rng, 100000)
        y = randn(rng, 100000)
        hexbin(x, y)
    end)]),

Example("Contour plot", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) .+ cos.(y)
        contour(x, y, z)
    end)]),

Example("Contour plot of matrix", [:(begin
        X = LinRange(-2, 2, 40)
        Y = LinRange(0, pi, 20)
        x, y = meshgrid(X, Y)
        z = sin.(x) .+ cos.(y)
        contour(x, y, z)
    end)]),

Example("Filled contour plot", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) .+ cos.(y)
        contourf(x, y, z)
    end)]),

Example("Filled contour plot of matrix", [:(begin
        X = LinRange(-2, 2, 40)
        Y = LinRange(0, pi, 20)
        x, y = meshgrid(X, Y)
        z = sin.(x) .+ cos.(y)
        contourf(x, y, z)
    end)]),

Example("Filled contour plot on a triangular mesh", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) + cos.(y)
        tricont(x, y, z)
    end)]),

Example("Surface plot", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) .+ cos.(y)
        surface(x, y, z)
    end)]),

Example("Surface plot of matrix", [:(begin
        X = LinRange(-2, 2, 40)
        Y = LinRange(0, pi, 20)
        x, y = meshgrid(X, Y)
        z = sin.(x) .+ cos.(y)
        surface(x, y, z)
    end)]),

Example("Surface plot on a triangular mesh", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) .+ cos.(y)
        trisurf(x, y, z)
    end)]),

Example("Wireframe plot", [:(begin
        x = 8 .* rand(rng, 100) .- 4
        y = 8 .* rand(rng, 100) .- 4
        z = sin.(x) .+ cos.(y)
        wireframe(x, y, z)
    end)]),

Example("Wireframe plot of matrix", [:(begin
        X = LinRange(-2, 2, 40)
        Y = LinRange(0, pi, 20)
        x, y = meshgrid(X, Y)
        z = sin.(x) .+ cos.(y)
        wireframe(x, y, z)
    end)]),

Example("Heatmap plot", [:(begin
        X = LinRange(-2, 2, 40)
        Y = LinRange(0, pi, 20)
        x, y = meshgrid(X, Y)
        z = sin.(x) .+ cos.(y)
        heatmap(z)
    end)]),

Example("Image plot", [:(begin
        imshow(z)
    end)]),

Example("Isosurface plot", [:(begin
        s = LinRange(-1, 1, 40)
        x, y, z = meshgrid(s, s, s)
        v = 1 .- (x .^ 2 .+ y .^ 2 .+ z .^ 2) .^ 0.5
        isosurface(v, isovalue=0.2)
    end)]),

Example("Shade points", [:(begin
        GR.GR3.terminate()

        volume(randn(rng, 50, 50, 50))

        N = 1_000_000
        x = randn(rng, N)
        y = randn(rng, N)
        shade(x, y)
    end)]),

Example("Discrete plot", [:(begin
        clearws()
        xd = -2 .+ 4 * rand(rng, 100)
        yd = -2 .+ 4 * rand(rng, 100)
        zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

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
        emergencyclosegks()
    end)])
]

function basic_tests()
    @test GR.tick(1.2,3.14) == 0.5
    
    for ex in _examples
        @info("Testing plot: $(ex.title)")
    
        GR.inline("pdf")
        file_path = ENV["GKS_FILEPATH"]
    
        map(eval, ex.code)
    
        @test isfile(file_path)
        rm(file_path)
    end
end

@time basic_tests()
