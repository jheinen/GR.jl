using GR

const maps=["uniform", "temperature", "grayscale", "glowing", "rainbowlike", "geologic", "greenscale", "cyanscale", "bluescale", "magentascale", "redscale", "flame", "brownscale", "pilatus", "autumn", "bone", "cool", "copper", "gray", "hot", "hsv", "jet", "pink", "spectral", "spring", "summer", "winter", "gist_earth", "gist_heat", "gist_ncar", "gist_rainbow", "gist_stern", "afmhot", "brg", "bwr", "coolwarm", "CMRmap", "cubehelix", "gnuplot", "gnuplot2", "ocean", "rainbow", "seismic", "terrain", "viridis", "inferno", "plasma", "magma"]

function main()
    a = round.(Int32,LinRange(1000,1255,256))
    xl = 0
    setwsviewport(0, 0.25, 0, 0.125)
    setwswindow(0, 1, 0, 0.5)
    setviewport(0.05, 0.95, 0.025, 0.475)
    setcharheight(0.010)
    setcharup(-1,0)
    settextcolorind(255)
    for cmap in 0:47
        setcolormap(cmap)
        xr = (cmap + 1) / 48.0
        cellarray(xl+0.002, xr-0.002, 0.2, 1, 1, 256, a)
        settextalign(1,3)
        text(0.04 + xr * 0.9, 0.48, string(cmap))
        settextalign(3,3)
        text(0.04 + xr * 0.9, 0.1, string(maps[cmap+1]))
        xl = xr
    end
end

main()
