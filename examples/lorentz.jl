using GR

Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.02
    σ::Float64 = 10
    ρ::Float64 = 28
    β::Float64 = 8/3
    x::Float64 = 1
    y::Float64 = 1
    z::Float64 = 1
end

function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x)
    l.x += l.dt * dx
    
    dy = l.x * (l.ρ - l.z) - l.y
    l.y += l.dt * dy
    
    dz = l.x * l.y - l.β * l.z
    l.z += l.dt * dz
end

attractor = Lorenz()
x = [1.0]
y = [1.0]
z = [1.0]

for i = 1:1500
    step!(attractor)
    push!(x, attractor.x)
    push!(y, attractor.y)
    push!(z, attractor.z)

    plot3(x, y, z, xlim = (-30, 30), ylim = (-30, 30), zlim = (0, 60), title = "Lorenz Attractor")
end
