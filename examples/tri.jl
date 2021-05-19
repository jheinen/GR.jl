ENV["GKS_DOUBLE_BUF"] = "True"

using GR
using BenchmarkTools

const GDP_DRAW_TRIANGLES = 4

function points_from_image(img, npts)
  w, h = size(img)
  xpts = Float64[]
  ypts = Float64[]
  cols = Int32[]
  for i in 1:npts
    x = rand() * w
    y = rand() * h
    c = img[Int64(floor(x)) + 1, Int64(floor(h-y)) + 1] & 0xffffff
    r = ( c        & 0xff) / 255.0
    g = ((c >> 8 ) & 0xff) / 255.0
    b = ((c >> 16) & 0xff) / 255.0
    if 0.2989 * r + 0.5870 * g + 0.1140 * b > 0.8
      if rand() < 0.1
        push!(xpts, x)
        push!(ypts, y)
        push!(cols, 0xc0c0c0)
      end
      continue
    end
    push!(xpts, x)
    push!(ypts, y)
    push!(cols, c)
  end
  xpts, ypts, cols
end

w, h, img = readimage("julia_logo.png")
x, y, cols = points_from_image(img, 100_000)

setwsviewport(0, 0.24, 0, 0.16)
setwswindow(0, 1, 0, 2/3)

setviewport(0, 1, 0, 2/3)
setwindow(0, w, 0, h)

setmarkersize(2/3)
setborderwidth(0.2)
setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)

settransparency(0.5)
polymarker(x, y)

n, tri = delaunay(x, y)
@show n

tri = convert(Matrix{Int32}, tri)
color = zeros(Int32, n)
for i in 1:n
    color[i] = cols[tri[i,1]]
end
attributes = vec(hcat(tri, color)')

setlinewidth(0.4)

# Draw a vector of triangles for given vertices x and y using point indices and color triplets
#   x: x coordinates
#   y: y coordinates
#   attributes: indices of the triangle points (i₁₁, i₁₂, i₁₃, rrggbb₁, i₂₁, i₂₂, i₂₃, rrggbb₂, ...)
@time gdp(x, y, GDP_DRAW_TRIANGLES, attributes)

updatews()
