using GR
using Base.Test

@test tick(1.2,3.14) == 0.5

tests = [ "ex", "griddata" ]

for t in tests
    tp = joinpath(Pkg.dir("GR"), "test", "$(t).jl")
    println("running $(tp) ...")
    inline("pdf")
    include(tp)
    @test isfile("gks.pdf")
    rm("gks.pdf")
end
