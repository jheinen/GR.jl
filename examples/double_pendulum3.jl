#!/usr/bin/env julia

import GR
const gr3 = GR.gr3

const g = 9.8        # gravitational constant

function rk4(x, h, y, f)
    k1 = h * f(x, y)
    k2 = h * f(x + 0.5 * h, y + 0.5 * k1)
    k3 = h * f(x + 0.5 * h, y + 0.5 * k2)
    k4 = h * f(x + h, y + k3)
    return x + h, y + (k1 + 2 * (k2 + k3) + k4) / 6.0
end

function double_pendulum(theta, length, mass)
    GR.clearws()
    GR.setviewport(0, 1, 0, 1)

    direction = zeros(3, 2)
    position = zeros(3, 3)
    for i=1:2
        direction[:,i] = [ sin(theta[i]) * length[i] * 2,
                          -cos(theta[i]) * length[i] * 2, 0]
        position[:,i+1] = position[:,i] + direction[:,i]
    end

    gr3.clear()
    # draw pivot point
    gr3.drawcylindermesh(1, [0,0.2,0], [0,1,0], [0.4,0.4,0.4], [0.4], [0.05])
    gr3.drawcylindermesh(1, [0,0.2,0], [0,-1,0], [0.4,0.4,0.4], [0.05], [0.2])
    gr3.drawspheremesh(1, [0,0,0], [0.4,0.4,0.4], [0.05])
    # draw rods
    gr3.drawcylindermesh(2, position, direction,
                         [0.6 for i=1:6], [0.05, 0.05], length * 2)
    # draw bobs
    gr3.drawspheremesh(2, position[:,2:3], [1 for i=1:6], mass * 0.2)

    gr3.drawimage(0, 1, 0, 1, 500, 500, gr3.DRAWABLE_GKS)
    GR.updatews()
end

function main()

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
        return ([w1, (e*d-b*f) / (a*d-c*b), w2, (a*f-c*e) / (a*d-c*b)])
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

    GR.setprojectiontype(2)
    gr3.setcameraprojectionparameters(45, 1, 100)
    gr3.cameralookat(6, -2, 4, 0, -2, 0, 0, 1, 0)
    gr3.setbackgroundcolor(1, 1, 1, 1)
    gr3.setlightdirection(1, 1, 10)

    now = start = time_ns()

    while t < 30
        t, state = rk4(t, dt, state, derivs)
        t1, w1, t2, w2 = state
        double_pendulum([t1, t2], [l1, l2], [m1, m2])

        now = (time_ns() - start) / 1000000000
        if t > now
            sleep(t - now)
        end
    end
end

main()
