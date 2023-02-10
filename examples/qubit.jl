using GR

function tα_qubit(β, ψ1, ψ2, fα, f)
    2 + 2 * β - cos(ψ1) - cos(ψ2) - 2 * β * cos(π * fα) * cos(2 * π * f + π * fα - ψ1 - ψ2)
end
ψ1 = ψ2 = range(0, 4 * π, length=100)
z = [tα_qubit(0.61, x, y, 0.2, 0.1) for x in ψ1, y in ψ2]

contour(ψ1, ψ2, z, levels=20, xlabel="ψ1", ylabel="ψ2", xlim=(0, 4π), ylim=(0, 4π))
