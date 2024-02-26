import GLFW

import GR
const gr3 = GR.gr3

function display()
  steps = (1.0 / size(data)[1], 1.0 / size(data)[2], 1.0 / size(data)[3])
  offsets = (-0.5, -0.5, -0.5)
  mesh = gr3.createisosurfacemesh(data, steps, offsets, isolevel)
  gr3.drawmesh(mesh, 1, (0, 0, 0), (0, 0, 1), (0, 1, 0), (1, 1, 1), (1, 1, 1))
  r = 1.5
  gr3.cameralookat(center[1], center[2], center[3], 0, 0, 0, up[1], up[2], up[3])
  gr3.drawimage(0.0, w, 0.0, h, width, height, gr3.DRAWABLE_OPENGL)

  GLFW.SwapBuffers(window)
  gr3.deletemesh(mesh)
  gr3.clear()
end

function spherical_to_cartesian(r, theta, phi)
  x = r * sin.(theta) * cos.(phi)
  y = r * sin.(theta) * sin.(phi)
  z = r * cos.(theta)
  return (x, y, z)
end

function cursor(motion, x, y)
  global center, up
  global isolevel

  if GLFW.GetMouseButton(window, GLFW.MOUSE_BUTTON_1)
    center = spherical_to_cartesian(-2, pi * y / height + pi/2, pi * x / width)
    up = spherical_to_cartesian(1, pi * y / height + pi, pi * x / width)
  elseif GLFW.GetMouseButton(window, GLFW.MOUSE_BUTTON_2)
    if y >= 0
      isolevel = round(Int, 255 * y / height)
    end
  end
  display()
end
 
ENV["GR3_USE_OPENGL"] = "true"

f = open("brain.bin", "r")
data = Vector{UInt16}(undef, 5120000)
data = reshape(read!(f, data), 200, 160, 160)
close(f)

width = height = 500
isolevel = 128
center = (0., 0., 2.)
up = (-1., 0., 0.)

monitor = GLFW.GetPrimaryMonitor()
xscale, yscale = GLFW.GetMonitorContentScale(monitor)
w = xscale * width
h = yscale * height

window = GLFW.CreateWindow(width, height, "MRI example")
GLFW.MakeContextCurrent(window)
GLFW.SetCursorPosCallback(window, cursor)

gr3.setbackgroundcolor(1, 1, 1, 0)

while !GLFW.WindowShouldClose(window)
  GLFW.PollEvents()
end

GLFW.DestroyWindow(window)
