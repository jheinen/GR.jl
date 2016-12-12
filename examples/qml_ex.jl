ENV["QSG_RENDER_LOOP"] = "basic"
using CxxWrap # for safe_cfunction
using QML
using GR

qmlfile = joinpath(dirname(Base.source_path()), "qml_ex.qml")

type Parameters
  nbins::Float64
end

parameters = Parameters(30)
w, h = (600, 450)

# Called from QQuickPaintedItem::paint with the QPainter as an argument
function paint(p::QPainter)
  global w, h

  ENV["GKSwstype"] = 381
  ENV["GKSconid"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p)
  w, h = width(dev), height(dev)

  plt = gcf()
  plt[:size] = (w * 0.72, h * 0.72)

  nbins = Int64(round(parameters.nbins))
  hexbin(randn(1000000), randn(1000000),
         nbins=nbins, xlim=(-5,5), ylim=(-5,5), title="nbins: $nbins")

  return
end

function mousePosition(eventx, eventy)
  sizex = 0.5 * w
  sizey = 0.5 * h
  q = max(sizex, sizey)
  xn = eventx / q
  yn = eventy / q
  x, y = ndctowc(xn, yn)
  "($(round(x,4)), $(round(-y,4)))"
end

# Convert to cfunction, passing the painter as void*
paint_cfunction = safe_cfunction(paint, Void, (QPainter,))

# paint_cfunction becomes a context property
@qmlapp qmlfile paint_cfunction parameters

@qmlfunction mousePosition

exec()
