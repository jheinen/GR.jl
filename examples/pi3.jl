using GR
using LaTeXStrings

f(x) = x*exp(-2x*im)
x = 0:0.01:π
w = f.(x)

setscientificformat(3)

plot3(real.(w), imag.(w), abs.(w), linewidth=3, xlabel=L"\Re e\{f(x)\}", ylabel=L"\Im e\{f(x)\}", zlabel=L"|f(x)|", title=L"f(x) = xe^{-2xi} \forall x \in [0,\pi]")
