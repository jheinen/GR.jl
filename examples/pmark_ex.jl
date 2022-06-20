using GR
 
d, h = 200, 1200  # pixel density (= image width) and image height
n, r = 800, 1000  # number of iterations and escape radius (r > 2)
 
x = range(0, 2, length=d+1)
y = range(0, 2 * h / d, length=h+1)
 
A, B = x .* pi, y .* pi
C = (.- 8.0im) .* exp.((A' .+ B .* im) .* im) .- 0.7436636774 .+ 0.1318632144im
 
Z, dZ = zero(C), zero(C)
D = zeros(size(C))
 
for k in 1:n
    M = abs2.(Z) .< abs2(r)
    Z[M], dZ[M] = Z[M] .^ 2 .+ C[M], 2 .* Z[M] .* dZ[M] .+ 1
end
 
N = abs.(Z) .> 2  # exterior distance estimation
D[N] = 0.5 .* log.(abs.(Z[N])) .* abs.(Z[N]) ./ abs.(dZ[N])
 
X, Y = real(C), imag(C)  # zoom images (adjust circle size 120 and zoom level 20 as needed)
R, c, z = 120 .* 2 ./ d .* pi .* exp.(.- ones(d+1)' .* B), min(d, h) + 1, max(0, h - d) ÷ 20

setwsviewport(0, 0.3, 0, 0.3)
setviewport(0, 1, 0, 1)
setwindow(-2.5, 1, -1.6, 1.9)

setcolormap(GR.COLORMAP_UNIFORM)
setborderwidth(0)
setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)

polymarker(vec(X[1*z+1:1*z+c,:]), vec(Y[1*z+1:1*z+c,:]), vec(R[1*z+1:1*z+c,:]), vec(D[1*z+1:1*z+c,:].^0.5))

updatews()

