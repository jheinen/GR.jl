using GR
using LaTeXStrings

formula = L"- \frac{{\hbar ^2}}{{2m}}\frac{{\partial ^2 \psi (x,t)}}{{\partial x^2 }} + U(x)\psi (x,t) = i\hbar \frac{{\partial \psi (x,t)}}{{\partial t}}"

selntran(0)

settextfontprec(232, 3)
settextalign(2, 3)
setbordercolorind(6)

mathtex(0.5, 0.5, formula)

tbx, tby = inqmathtex(0.5, 0.5, formula)
Δx = (tbx[2] - tbx[1]) / √2
Δy = (tby[3] - tby[1]) / √2
path([0.5+Δx, Δx, 2π], [0.5, Δy, 0], "MAs");

updatews()
