#
# Atomic Orbitals - based on Christina C. Lee's blog post
# (see https://albi3ro.github.io/M4/prerequisites/Atomic-Orbitals.html)
#

using GSL    # GSL holds the special functions
using GR

a0 = 5.291772109217e-11

# The unitless radial coordinate
ρ(r,n) = 2r/(n*a0)

# The θ and ϕ dependence
function Yml(m::Int,l::Int,θ::Real,ϕ::Real)
    (-1.0)^m*sf_legendre_Plm(l,abs(m),cos(θ))*ℯ^(im*m*ϕ)
end

# The Radial dependence
function R(n::Int,l::Int,ρ::Real)
    sf_laguerre_n(n-l-1,2*l+1,ρ)*ℯ^(-ρ/2)*ρ^l
end

# A normalization: This is dependent on the choice of polynomial representation
function norm(n::Int,l::Int)
    sqrt((2/n)^3 * factorial(n-l-1)/(2n*factorial(n+l)))
end

# Generates an Orbital Funtion of (r,θ,ϕ) for a specificied n,l,m.
function Orbital(n::Int,l::Int,m::Int)
    # we make sure l and m are within proper bounds
    if l > n || abs(m) > l
        throw(DomainError())
    end
    Ψ(ρ,θ,ϕ) = norm(n,l) * R(n,l,ρ) * abs(Yml(m,l,θ,ϕ))
    Ψ
end

function CarttoSph(x::Array,y::Array,z::Array)
    r = sqrt.(x.^2+y.^2+z.^2)
    θ = acos.(z./r)
    ϕ = atan.(y./x)
    r,θ,ϕ
end

function calculate_electronic_density(n,l,m)
    N = 50
    r = 1e-9
    s = LinRange(-r,r,N)
    x,y,z = meshgrid(s,s,s)
    
    r,θ,ϕ = CarttoSph(x,y,z)
    Ψ = Orbital(n,l,m)

    Ψv = zeros(Float32,N,N,N)
    for i in 1:N
        for j in 1:N
            for k in 1:N
                Ψv[i,j,k] = abs(Ψ(ρ(r[i,j,k],n),θ[i,j,k],ϕ[i,j,k]))
            end
        end
    end

    (Ψv.-minimum(Ψv))./(maximum(Ψv).-minimum(Ψv))
end

Ψv = calculate_electronic_density(3,2,0)

for alpha in 0:360
    isosurface(Ψv,isovalue=0.25,rotation=alpha)
end
