ENV["GKS_WSTYPE"] = "100"

using GR
using Printf
using BenchmarkTools

w, h = (800, 600)

image = rand(UInt32, w, h)  # allocate the memory
mem = Printf.@sprintf("%p", pointer(image))
conid = Printf.@sprintf("!%dx%d@%s.mem",  w, h, mem[3:end])

@btime begin
    beginprint(conid)
    plot(rand(1000), size=(w, h))
    endprint()
end

emergencyclosegks()

delete!(ENV, "GKS_WSTYPE") 

mwidth, mheight, width, height = inqdspsize()
size = 400 * mwidth / width

setwsviewport(0, size, 0, 3/4 * size)
setwswindow(0, 1, 0, 3/4)

setviewport(0, 1, 0, 3/4)
setwindow(0, 1, 0, 3/4)

drawimage(0, 1, 0, 3/4, w, h, image)
updatews()
