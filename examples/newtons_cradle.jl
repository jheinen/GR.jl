#!/usr/bin/env julia

import GR

function rk4(x, h, y, f)
  k1 = h * f(x, y)
  k2 = h * f(x + 0.5 * h, y + 0.5 * k1)
  k3 = h * f(x + 0.5 * h, y + 0.5 * k2)
  k4 = h * f(x + h, y + k3)
  return x + h, y + (k1 + 2 * (k2 + k3) + k4) / 6.0
end

function deriv(t, state)
  theta, omega = state
  return [omega, -gamma * omega - 9.81 / L * sin(theta)]
end

function draw_cradle(theta)
  GR.clearws()
  GR.setviewport(0, 1, 0, 1)
  GR.setcolorrep(1, 0.7, 0.7, 0.7)
  # draw pivot point
  GR.fillarea([0.3, 0.7, 0.7, 0.3], [0.79, 0.79, 0.81, 0.81])
  # draw balls
  for i = -2:2
    x = [0.5, 0.5] + i * 0.06
    y = [0.8, 0.4]
    if (theta < 0 && i == -2) || (theta > 0 && i == 2)
      x[2] += sin(theta) * 0.4
      y[2] = 0.8 - cos(theta) * 0.4
    end
    GR.polyline(x, y)               # draw wire
    GR.drawimage(x[2]-0.03, x[2]+0.03, y[2]-0.03, y[2]+0.03, 50, 50, ball)
  end
  GR.updatews()
end

theta = 70.0   # initial angle
gamma = 0.1    # damping coefficient
L = 0.2        # wire length

t = 0.0
dt = 0.01
state = [theta * pi / 180, 0]

w, h, ball = GR.readimage("ball.png")

start = refresh = time_ns()

while t < 30
  t, state = rk4(t, dt, state, deriv)
  theta, omega = state

  if time_ns() - refresh > 20 * 1000000   # 20ms
    draw_cradle(theta)
    refresh = time_ns()
  end

  now = (time_ns() - start) / 1000000000
  if t > now
      sleep(t - now)
  end
end
