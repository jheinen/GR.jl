#!/usr/bin/env julia

import GR
using LaTeXStrings
using Printf

const g = 9.81       # gravity acceleration
const Γ = 0.1        # damping coefficient

function main()

    function rk4(x, h, y, f)
        k1 = h * f(x, y)
        k2 = h * f(x + 0.5 * h, y + 0.5 * k1)
        k3 = h * f(x + 0.5 * h, y + 0.5 * k2)
        k4 = h * f(x + h, y + k3)
        x + h, y + (k1 + 2 * (k2 + k3) + k4) / 6.0
    end

    function derivs(t, state)
        θ, ω = state
        [ω, -Γ * ω - g / L * sin(θ)]
    end

    function pendulum(t, θ, ω, acceleration)
        GR.clearws()
        GR.setviewport(0, 1, 0, 1)
    
        x = [0.5, 0.5 + sin(θ) * 0.4]
        y = [0.8, 0.8 - cos(θ) * 0.4]
        # draw pivot point
        GR.fillarea([0.46, 0.54, 0.54, 0.46], [0.79, 0.79, 0.81, 0.81]),
    
        GR.setlinecolorind(1)
        GR.setlinewidth(2)
        GR.polyline(x, y)  # draw rod
        GR.setmarkersize(5)
        GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
        GR.setmarkercolorind(86)
        GR.setborderwidth(0)
        GR.polymarker([x[2]], [y[2]])  # draw bob
        GR.setlinecolorind(4)
        V = 0.05 * ω  # show angular velocity
        GR.drawarrow(x[2], y[2], x[2] + V * cos(θ), y[2] + V * sin(θ))
        GR.setlinecolorind(2)
        A = 0.05 * acceleration  # show angular acceleration
        GR.drawarrow(x[2], y[2], x[2] + A * sin(θ), y[2] + A * cos(θ))
    
        GR.settextfontprec(232, 3) # CM Serif Roman
        GR.setcharheight(0.032)
        GR.settextcolorind(1)
        GR.text(0.05, 0.95, "Damped Pendulum")
        GR.setcharheight(0.040)
        GR.text(0.4, 0.22, L"\omega=\dot{\theta}")
        GR.text(0.4, 0.1, L"\dot{\omega}=-\gamma\omega-\frac{g}{l}sin(\theta)")
        GR.settextfontprec(GR.FONT_COURIER, 0) # Courier
        GR.setcharheight(0.024)
        GR.text(0.05, 0.22, "t:$(@sprintf("%7.2f", t))")
        GR.text(0.05, 0.16, "θ:$(@sprintf("%7.2f", θ / π * 180))")
        GR.settextcolorind(4)
        GR.text(0.05, 0.10, "ω:$(@sprintf("%7.2f", ω))")
        GR.settextcolorind(2)
        GR.text(0.05, 0.04, "A:$(@sprintf("%7.2f", acceleration))")

        GR.updatews()
    end

    θ = 70.0       # initial angle
    L = 1          # pendulum length

    t = 0
    dt = 0.04
    state = [θ * π / 180, 0]

    now = start = time_ns()

    while t < 30
        t, state = rk4(t, dt, state, derivs)
        θ, ω = state
        acceleration = sqrt(2 * g * L * (1 - cos(θ)))
        pendulum(t, θ, ω, acceleration)

        now = (time_ns() - start) / 1000000000
        if t > now
            sleep(t - now)
        end
    end
end

main()
