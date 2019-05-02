using GR

const viridis = [0x440154, 0x472c7a, 0x3b518b, 0x2c718e, 0x21908d, 0x27ad81, 0x5cc863, 0xaadc32, 0xfde725]
const inferno = [0x000004, 0x1f0c48, 0x550f6d, 0x88226a, 0xa83655, 0xe35933, 0xf9950a, 0xf8c932, 0xfcffa4]
const plasma = [0x0c0887, 0x4b03a1, 0x7d03a8, 0xa82296, 0xcb4679, 0xe56b5d, 0xf89441, 0xfdc328, 0xf0f921]
const magma = [0x000004, 0x1c1044, 0x4f127b, 0x812581, 0xb5367a, 0xe55964, 0xfb8761, 0xfec287, 0xfbfdbf]

red(a)   = ((a .>> 16) .& 0xff ) ./ 256
green(a) = ((a .>>  8) .& 0xff ) ./ 256
blue(a)  = ( a         .& 0xff ) ./ 256

function show_colormaps()
    setwindow(1, 5, 0, 1)
    for (x, cmap) in enumerate((viridis, inferno, plasma, magma))
        setcolormapfromrgb(red(cmap), green(cmap), blue(cmap))
        cellarray(x, x + 0.25, 0, 1, 1, 255, 1000:1255)
        setcolormap(GR.COLORMAP_VIRIDIS + x - 1)
        cellarray(x + 0.5, x + 0.75, 0, 1, 1, 255, 1000:1255)
    end
    updatews()
end

show_colormaps()
