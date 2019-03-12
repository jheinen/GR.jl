using GR

setcolormapfromrgb( [68, 59, 33, 83, 253] ./ 256,
                    [1, 80, 141, 197, 231] ./ 256,
                    [84, 139, 141, 104, 37] ./ 256,
                    positions = [0, 250, 500, 750, 1024] ./ 1024.)
cellarray(0, 1, 0, 0.45, 255, 1, 1000:1255)

setcolormap(GR.COLORMAP_VIRIDIS)
cellarray(0, 1, 0.55, 1, 255, 1, 1000:1255)

updatews()
