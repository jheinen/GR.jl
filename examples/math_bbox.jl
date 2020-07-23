using GR
using LaTeXStrings

formulas = (
    L"- \frac{{\hbar ^2}}{{2m}}\frac{{\partial ^2 \psi (x,t)}}{{\partial x^2 }} + U(x)\psi (x,t) = i\hbar \frac{{\partial \psi (x,t)}}{{\partial t}}",
    L"\zeta \left({s}\right) := \sum_{n=1}^\infty \frac{1}{n^s} \quad \sigma = \Re(s) > 1",
    L"\zeta \left({s}\right) := \frac{1}{\Gamma(s)} \int_{0}^\infty \frac{x^{s-1}}{e^x-1} dx" )

selntran(0)

settextfontprec(232, 3)
settextalign(2, 3)
chh = 0.036

for phi in LinRange(0, 2pi, 360)
    clearws()
    setcharheight(chh)
    setcharup(sin(phi), cos(phi))
    y = 0.6
    for s in formulas
        mathtex(0.5, y, s)
        tbx, tby = inqmathtex(0.5, y, s)
        fillarea(tbx, tby)
        y -= 0.2
    end
    updatews()
end
