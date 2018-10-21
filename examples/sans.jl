using Compat

using GR

@static if VERSION >= v"0.7.0-DEV.3406"
    using DelimitedFiles
end

function main()
    z = Z = readdlm("sans.dat")
    G = [ exp(-x^2 -y^2) for x in LinRange(-1.5, 1.5, 128), y in LinRange(-1.5, 1.5, 128) ]

    for t = 0:500
        surface(z, title="Time: $t s")
        z += 0.05 * Z .* G .* rand(Float64, (128, 128))
    end
end

main()
