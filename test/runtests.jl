import GR

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end
@static if VERSION >= v"0.7.0-DEV.3406"
    using Random
end

@test GR.tick(1.2,3.14) == 0.5

tests = [ "ex", "griddata" ]

for t in tests
    tp = joinpath(dirname(@__FILE__), "$(t).jl")
    println("running $(tp) ...")
    GR.inline("pdf")
    include(tp)
    file_path = ENV["GKS_FILEPATH"]
    @test isfile(file_path)
    rm(file_path)
end
