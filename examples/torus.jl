using GR
using LaTeXStrings

setscientificformat(3)

R, r = 2, 1/2
θ = φ = LinRange(0, 2π, 200)
f(θ, φ) = ((R + r*cos(θ)) * cos(φ), (R + r*cos(θ)) * sin(φ), r * sin(θ))
x, y, z = [[v[i] for v in f.(θ, φ')] for i in 1:3]

surface(x, y, z, xlabel=L"x(\theta,\varphi) = R + r \cos \theta \cos \varphi", ylabel=L"y(\theta,\varphi) = R + r \cos \theta \sin \varphi", zlabel=L"z(\theta,\varphi) = r \sin \theta", title="Torus")
