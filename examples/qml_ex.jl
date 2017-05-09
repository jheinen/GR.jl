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

  nbins = Int64(round(parameters.nbins))
  hexbin(randn(1000000), randn(1000000),
         nbins=nbins, xlim=(-5,5), ylim=(-5,5), title="nbins: $nbins")

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

# Convert to cfunction, passing the painter as void*
paint_cfunction = safe_cfunction(paint, Void, (QML.QPainterRef, QML.JuliaPaintedItemRef))

# paint_cfunction becomes a context property
@qmlapp qmlfile paint_cfunction parameters

@qmlfunction mousePosition

exec()
