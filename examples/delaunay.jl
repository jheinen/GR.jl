using GR
using Images

function points_from_image(img, npts)
  w, h = size(img)
  xpts = Float64[]
  ypts = Float64[]
  cols = Int[]
  for i in 1:npts
    x = rand() * w
    y = rand() * h
    c = img[Int64(floor(x)) + 1, Int64(floor(h-y)) + 1]
    if 0.2989 * c.r + 0.5870 * c.g + 0.1140 * c.b > 0.8
      if rand() < 0.1
        push!(xpts, x)
        push!(ypts, y)
        push!(cols, 1)
      end
      continue
    end
    push!(xpts, x)
    push!(ypts, y)
    push!(cols, inqcolorfromrgb(c.r, c.g, c.b))
  end
  xpts, ypts, cols
end

img = load("julia_logo.png")
x, y, cols = points_from_image(img', 30000)

settransparency(0.5)
setmarkersize(0.5)
scatter(x, y, size=(900,600))

n, tri = delaunay(x, y)
for i in 1:n
  if all(cols[tri[i,:]] .!= 1)
    settransparency(0.5)
    setfillcolorind(cols[tri[i,1]])
  else
    settransparency(0.1)
    setfillcolorind(1)
  end
  fillarea(x[tri[i,:]], y[tri[i,:]])
end

