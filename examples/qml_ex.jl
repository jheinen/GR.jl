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
function paint(p::QPainter, item::JuliaPaintedItem)
  global w, h

  ENV["GKSwstype"] = 381
  ENV["GKSconid"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p)
  w, h = width(dev), height(dev)
  r = effectiveDevicePixelRatio(window(item))

  plt = gcf()
  plt[:size] = (w/r, h/r)

  nbins = Int64(round(parameters.nbins))
  hexbin(randn(1000000), randn(1000000),
         nbins=nbins, xlim=(-5,5), ylim=(-5,5), title="nbins: $nbins")

  return
end

function mousePosition(eventx, eventy)
  xn = eventx / w
  yn = eventy / h
  if w > h
    yn = yn * h / w
  else
    xn = xn * w / h
  end
  x, y = ndctowc(xn, yn)
  "($(round(x,4)), $(round(-y,4)))"
end

# Convert to cfunction, passing the painter as void*
paint_cfunction = safe_cfunction(paint, Void, (QPainter,JuliaPaintedItem))

# paint_cfunction becomes a context property
@qmlapp qmlfile paint_cfunction parameters

@qmlfunction mousePosition

exec()
