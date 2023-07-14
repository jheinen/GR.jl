#!/usr/bin/env julia

import GR

const g = 9.8        # gravitational constant

function main()

    function rk4(x, h, y, f)
        k1 = h * f(x, y)
        k2 = h * f(x + 0.5 * h, y + 0.5 * k1)
        k3 = h * f(x + 0.5 * h, y + 0.5 * k2)
        k4 = h * f(x + h, y + k3)
        x + h, y + (k1 + 2 * (k2 + k3) + k4) / 6.0
    end

    function derivs(t, state)
        # The following derivation is from:
        # http://scienceworld.wolfram.com/physics/DoublePendulum.html
        t1, w1, t2, w2 = state
        a = (m1 + m2) * l1
        b = m2 * l2 * cos(t1 - t2)
        c = m2 * l1 * cos(t1 - t2)
        d = m2 * l2
        e = -m2 * l2 * w2^2 * sin(t1 - t2) - g * (m1 + m2) * sin(t1)
        f =  m2 * l1 * w1^2 * sin(t1 - t2) - m2 * g * sin(t2)
        [w1, (e*d-b*f) / (a*d-c*b), w2, (a*f-c*e) / (a*d-c*b)]
    end

    function pendulum(theta, length, mass)
        l = length[1] + length[2]
        GR.clearws()
        GR.setviewport(0, 1, 0, 1)
        GR.setwindow(-l, l, -l, l)
        GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
        GR.setmarkercolorind(86)
        GR.setborderwidth(0)
        pivot = [0, 0.775]                         # draw pivot point
        GR.fillarea([-0.2, 0.2, 0.2, -0.2], [0.75, 0.75, 0.8, 0.8])
        for i in 1:2
            x = [pivot[1], pivot[1] + sin(theta[i]) * length[i]]
            y = [pivot[2], pivot[2] - cos(theta[i]) * length[i]]
            GR.polyline(x, y)                   # draw rod
            GR.setmarkersize(3 * mass[i])
            GR.polymarker([x[2]], [y[2]])       # draw bob
            pivot = [x[2], y[2]]
        end
        GR.updatews()
    end

    l1 = 1.2       # length of rods
    l2 = 1.0
    m1 = 1.0       # weights of bobs
    m2 = 1.5
    t1 = 100.0     # inintial angles
    t2 = -20.0

    w1 = 0.0
    w2 = 0.0
    t = 1.0
    dt = 0.04
    state = [t1, w1, t2, w2] * pi / 180

    now = start = time_ns()

    while t < 30
        t, state = rk4(t, dt, state, derivs)
        t1, w1, t2, w2 = state
        pendulum([t1, t2], [l1, l2], [m1, m2])

        now = (time_ns() - start) / 1000000000
        if t > now
            sleep(t - now)
        end
    end
end

main()
