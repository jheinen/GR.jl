using GR
using LaTeXStrings

f(x) = x*exp(-2x*im)
x = 0:0.01:π
w = f.(x)

plot(real.(w), imag.(w), x, linewidth=5, title=L"f(x) = xe^{-2xi} \forall x \in [0,\pi]", xlabel=L"\Re e\{f(x)\}", ylabel=L"\Im e\{f(x)\}")
