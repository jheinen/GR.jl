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

# Arguments here need to be the "reference types", hence the "Ref" suffix
function paint(p::CxxPtr{QPainter}, item::CxxPtr{JuliaPaintedItem})
  global w, h

  ENV["GKS_WSTYPE"] = 381
  ENV["GKS_CONID"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p[])[]
  r = effectiveDevicePixelRatio(window(item[])[])
  w, h = width(dev) / r, height(dev) / r

  num_bins = Int64(round(nbins[]))
  histogram(randn(10000), nbins=num_bins, size=(w, h))

  return
end

function mousePosition(eventx, eventy, deltay)
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

loadqml(qmlfile,
  paint_cfunction = @safe_cfunction(paint, Cvoid, (CxxPtr{QPainter}, CxxPtr{JuliaPaintedItem})),
  parameters = JuliaPropertyMap("nbins" => nbins))

@qmlfunction mousePosition

exec()
