ENV["QSG_RENDER_LOOP"] = "basic"
using CxxWrap # for safe_cfunction
using QML
using Observables
using GR

const qmlfile = joinpath(dirname(Base.source_path()), "qml_ex.qml")

x = randn(1000000)
y = randn(1000000)
nbins = Observable(30)

w, h = (600, 450)
zoom = Nothing

# Called from QQuickPaintedItem::paint with the QPainterRef as an argument
function paint(p::QML.QPainterRef, item::QML.JuliaPaintedItemRef)
  global w, h
  global zoom

  ENV["GKSwstype"] = 381
  ENV["GKSconid"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p)
  r = effectiveDevicePixelRatio(window(item))
  w, h = width(dev) / r, height(dev) / r

  plt = gcf()
  plt[:size] = (w, h)

  if zoom === Nothing
    xmin, xmax, ymin, ymax = (-5, 5, -5, 5)
  elseif zoom != 0
    xmin, xmax, ymin, ymax = panzoom(0, 0, zoom)
  else
    xmin, xmax, ymin, ymax = inqwindow()
  end

  num_bins = Int64(round(nbins[]))
  hexbin(x, y, nbins=num_bins, xlim=(xmin, xmax), ylim=(ymin, ymax), title="nbins: $num_bins")

  return
end

function mousePosition(eventx, eventy, deltay)
  global zoom
  if deltay != 0
    zoom = deltay < 0 ? 1.02 : 1/1.02
  else
    zoom = 0
  end
  if w > h
    xn = eventx / w
    yn = (h - eventy) / w
  else
    xn = eventx / h
    yn = (h - eventy) / h
  end
  x, y = ndctowc(xn, yn)
  "($(round(x,digits=4)), $(round(y,digits=4)))"
end

load(qmlfile,
  paint_cfunction = @safe_cfunction(paint, Cvoid, (QML.QPainterRef, QML.JuliaPaintedItemRef)),
  nbins = nbins
)

@qmlfunction mousePosition

exec()
