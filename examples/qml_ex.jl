ENV["QSG_RENDER_LOOP"] = "basic"
using CxxWrap # for safe_cfunction
using QML
using Observables
using GR

const qmlfile = joinpath(dirname(Base.source_path()), "qml_ex.qml")

nbins = Observable(30)
w, h = (600, 450)

# Called from QQuickPaintedItem::paint with the QPainterRef as an argument
function paint(p::QML.QPainterRef, item::QML.JuliaPaintedItemRef)
  global w, h

  ENV["GKSwstype"] = 381
  ENV["GKSconid"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p)
  r = effectiveDevicePixelRatio(window(item))
  w, h = width(dev) / r, height(dev) / r

  plt = gcf()
  plt[:size] = (w, h)

  num_bins = Int64(round(nbins[]))
  hexbin(randn(1000000), randn(1000000),
         nbins=num_bins, xlim=(-5,5), ylim=(-5,5), title="nbins: $num_bins")

  return
end

function mousePosition(eventx, eventy)
  if w > h
    xn = eventx / w
    yn = (h - eventy) / w
  else
    xn = eventx / h
    yn = (h - eventy) / h
  end
  x, y = ndctowc(xn, yn)
  "($(round(x,4)), $(round(y,4)))"
end

load(qmlfile,
  paint_cfunction = @safe_cfunction(paint, Cvoid, (QML.QPainterRef, QML.JuliaPaintedItemRef)),
  nbins = nbins
)

exec()
