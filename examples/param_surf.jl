using GR

r = 1
θ, φ = meshgrid(range(0, stop=2π, length=200), range(0, stop=2π, length=100))

x = r * sin.(θ) .* sin.(φ)
y = r * sin.(θ) .* cos.(φ)
z = r * cos.(θ)

surface(x, y, z)

