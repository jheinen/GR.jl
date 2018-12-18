ENV["QSG_RENDER_LOOP"] = "basic"
using CxxWrap # for safe_cfunction
using QML
using Observables
using Plots
import GR

ENV["GKSwstype"] = "use_default"
gr(show=true)

const qmlfile = joinpath(dirname(Base.source_path()), "qml_ex.qml")

nbins = Observable(30)
w, h = (600, 450)

# Called from QQuickPaintedItem::paint with the QPainterRef as an argument
function paint(p::QML.QPainterRef, item::QML.JuliaPaintedItemRef)
  global w, h

  ENV["GKS_WSTYPE"] = 381
  ENV["GKS_CONID"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p)
  r = effectiveDevicePixelRatio(window(item))
  w, h = width(dev) / r, height(dev) / r

  num_bins = Int64(round(nbins[]))
  histogram(randn(10000), nbins=num_bins, size=(w, h))

  return
end

function mousePosition(eventx, eventy, deltay)
  println(deltay)
  if w > h
    xn = eventx / w
    yn = (h - eventy) / w
  else
    xn = eventx / h
    yn = (h - eventy) / h
  end
  x, y = GR.ndctowc(xn, yn)
  "($(round(x,digits=4)), $(round(y,digits=4)))"
end

load(qmlfile,
  paint_cfunction = @safe_cfunction(paint, Cvoid, (QML.QPainterRef, QML.JuliaPaintedItemRef)),
  nbins = nbins
)

@qmlfunction mousePosition

exec()
