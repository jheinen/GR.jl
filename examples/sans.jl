using GR

z = Z = readdlm("sans.dat")
G = [ exp(-x^2 -y^2) for x in linspace(-1.5, 1.5, 128), y in linspace(-1.5, 1.5, 128) ]

for t = 0:500
    plot3d(z, contours=false, accelerate=true, ztitle="Time: $t s",
           colormap=GR.COLORMAP_COOLWARM)
    z += 0.05 * Z .* G .* rand((128, 128))
end
