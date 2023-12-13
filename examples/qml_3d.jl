ENV["QSG_RENDER_LOOP"] = "basic"

using CxxWrap # for safe_cfunction
using QML
using Observables
using GR

const qmlfile = joinpath(dirname(Base.source_path()), "qml_3d.qml")

rot = -30
tilt = 45
fov = Observable(30)
cam = Observable(0.0)

w, h = (500, 500)

mouse = Nothing

function paint(p::CxxPtr{QPainter}, item::CxxPtr{JuliaPaintedItem})
  global rot, tilt

  ENV["GKSwstype"] = 381
  ENV["GKSconid"] = split(repr(p.cpp_object), "@")[2]

  dev = device(p[])[]
  r = effectiveDevicePixelRatio(window(item[])[])
  w, h = width(dev) / r, height(dev) / r

  clearws()

  mwidth, mheight, pwidth, pheight = inqdspsize()
  if w > h
    ratio = float(h) / w
    msize = mwidth * w / pwidth
    setwsviewport(0, msize, 0, msize * ratio)
    setwswindow(0, 1, 0, ratio)
  else
    ratio = float(w) / h
    msize = mheight * h / pheight
    setwsviewport(0, msize * ratio, 0, msize)
    setwswindow(0, ratio, 0, 1)
  end

  x = LinRange(-1, 1, 49)
  y = LinRange(-1, 1, 49)
  z = peaks()

  selntran(1)
  setwindow(-1, 1, -1, 1)
  setviewport(0.05, 0.95, 0.05, 0.95)
  setlinewidth(0.5) # should be adjusted internally!
  setresamplemethod(0x2020202) # linear
  setcharheight(0.016)
  settextfontprec(232, 4)

  setwindow3d(-1, 1, -1, 1, -10, 10)
  setspace3d(rot, tilt, fov[], cam[])
  settransparency(0.5)

  xtick, ytick, ztick = (0.1, 0.1, 1)
  xorg = (-1, 1)
  yorg = (-1, 1)
  zorg = (-10, 10)

  rotation = -rot
  while rotation < 0 rotation += 360 end
  while tilt < 0 tilt += 360 end
  zi = 0 <= tilt <= 90 ? 1 : 2

  if 0 <= rotation < 90
    grid3d(xtick, 0, ztick, xorg[1], yorg[2], zorg[zi], 2, 0, 2)
    grid3d(0, ytick, 0, xorg[1], yorg[2], zorg[zi], 0, 2, 0)
  elseif 90 <= rotation < 180
    grid3d(xtick, 0, ztick, xorg[2], yorg[2], zorg[zi], 2, 0, 2)
    grid3d(0, ytick, 0, xorg[2], yorg[2], zorg[zi], 0, 2, 0)
  elseif 180 <= rotation < 270
    grid3d(xtick, 0, ztick, xorg[2], yorg[1], zorg[zi], 2, 0, 2)
    grid3d(0, ytick, 0, xorg[2], yorg[1], zorg[zi], 0, 2, 0)
  else
    grid3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], 2, 0, 2)
    grid3d(0, ytick, 0, xorg[1], yorg[1], zorg[zi], 0, 2, 0)
  end

  settransparency(0.3)
  gr3.surface(x, y, z', 4)
  gr3.surface(x, y, z', 1)

  settransparency(0.8)

  setcharheight(0.016 * 1.5)
  titles3d("X title", "Y title", "Z title")
  
  setcharheight(0.016)
  if 0 <= rotation < 90
    axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[zi], 2, 0, 2, -0.01)
    axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[zi], 0, 2, 0, 0.01)
  elseif 90 <= rotation < 180
    axes3d(0, 0, ztick, xorg[1], yorg[2], zorg[zi], 0, 0, 2, -0.01)
    axes3d(xtick, ytick, 0, xorg[1], yorg[1], zorg[zi], 2, 2, 0, -0.01)
  elseif 180 <= rotation < 270
    axes3d(xtick, 0, ztick, xorg[2], yorg[2], zorg[zi], 2, 0, 2, 0.01)
    axes3d(0, ytick, 0, xorg[1], yorg[1], zorg[zi], 0, 2, 0, -0.01)
  else
    axes3d(0, 0, ztick, xorg[2], yorg[1], zorg[zi], 0, 0, 2, -0.01)
    axes3d(xtick, ytick, 0, xorg[2], yorg[2], zorg[zi], 2, 2, 0, 0.01)
  end

  updatews()

  return
end

function mousePosition(eventx, eventy, buttons)
  global mouse, rot, tilt
  if mouse != Nothing
    rot += 0.2 * (mouse[1] - eventx)
    tilt += 0.2 * (mouse[2] - eventy)
  end
  if buttons != 0
    mouse = [eventx, eventy]
  else
    mouse = Nothing
  end
end

loadqml(qmlfile,
  paint_cfunction = @safe_cfunction(paint, Cvoid, (CxxPtr{QPainter}, CxxPtr{JuliaPaintedItem})),
  parameters = JuliaPropertyMap("fov" => fov, "cam" => cam))

@qmlfunction mousePosition

exec()
