using GR

using DelimitedFiles

function main()
    z = Z = readdlm("sans.dat", skipstart=3)
    G = [ exp(-x^2 -y^2) for x in LinRange(-1.5, 1.5, 128), y in LinRange(-1.5, 1.5, 128) ]

    for t = 0:500
        surface(z, title="Time: $t s")
        z += 0.05 * Z .* G .* rand(Float64, (128, 128))
    end
end

main()
