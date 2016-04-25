#!/usr/bin/env julia

# A view of the Riemann Zeta function using the domain coloring method

if VERSION < v"0.4-"
  typealias UInt32 Uint32
end

import GR


function domain_colors(w, n)
    H = mod(angle(w[:]) / 2pi + 1, 1)
    m = 0.7
    M = 1
    isol = m + (M - m) * (H[:] * n - floor(H[:] * n))
    modul = abs(w[:])
    Logm = log(modul[:])
    modc = m + (M - m) * (Logm[:] - floor(Logm[:]))

    V = [modc[i] * isol[i] for i = 1:length(modc)]
    S = 0.9 * ones(H)
    HSV = cat(2, H, S, V)

    return HSV
end


function func_vals(f, re, im,  N)
    # evaluates the complex function at the nodes of the grid
    # re and im are tuples defining the rectangular region
    # N is the number of nodes per unit interval
    l = re[2] - re[1]
    h = im[2] - im[1]
    resL = N * l  # horizontal resolution
    resH = N * h  # vertical resolution
    x = linspace(re[1], re[2], resL)
    y = linspace(im[1], im[2], resH)
    x, y = GR.meshgrid(x, y)
    z = complex(x, y)
    w = f(z)
    return w
end


function plot_domain(color_func, f; re=[-1, 1], im=[-1, 1], N=100, n=15)
    w = func_vals(f, re, im, N)
    domc = color_func(w, n) * 255
    h = round(domc[:,1])
    s = round(domc[:,2])
    v = round(domc[:,3])
    alpha = 255
    width, height = size(w)
    c = Array(UInt32, width * height)
    c[:] = h + 256 * (s + 256 * (v + 256 * alpha))
    c = rotr90(reshape(c, width, height))

    GR.clearws()
    GR.setviewport(0.3725, 0.6275, 0.1, 0.95)
    GR.setwindow(-6, 6, -20, 20)
    GR.drawimage(-6, 6, -20, 20, height, width, c, GR.MODEL_HSV)
    GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)
    GR.setcharheight(0.018)
    GR.mathtex(0.825, 0.575, "\\zeta \\left({s}\\right) := \\sum_{n=1}^\\infty \\frac{1}{n^s} \\quad \\sigma = \\Re(s) > 1")
    GR.mathtex(0.825, 0.475, "\\zeta \\left({s}\\right) := \\frac{1}{\\Gamma(s)} \\int_{0}^\\infty \\frac{x^{s-1}}{e^x-1} dx")
    GR.axes(1, 1, -6, -20, 3, 10, -0.005)
    GR.setcharheight(0.024)
    GR.mathtex(0.5, 0.975, "\\zeta \\left({s}\\right)")
    GR.mathtex(0.5, 0.025, "\\Re(z)")
    GR.mathtex(0.3, 0.525, "\\Im(z)")
    GR.updatews()
end

f = zeta

for n = 5:30
    plot_domain(domain_colors, f, re=(-6, 6), im=(-20, 20), N=15, n=n)
end
