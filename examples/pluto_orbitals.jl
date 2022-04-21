### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 5323b5ac-0c51-4952-8f27-4f489c1f2d1a
begin
    import Pkg
    Pkg.activate() # disable Pluto's package management
end

# ╔═╡ d8aeb9f4-990c-11eb-0dbb-078cda4928d5
begin
    using GSL # provides the special functions
    using GR
    using PlutoUI
end

# ╔═╡ 6127fb6a-22fc-4f35-8228-cc06ffebf9c0
begin
    a0 = 5.291772109217e-11

    # The unitless radial coordinate
    ρ(r, n) = 2r/(n*a0)
end

# ╔═╡ 7aa443bd-b706-41e2-bdc8-0d8c10c99b02
# The θ and ϕ dependence
function Yml(m::Int, l::Int, θ::Real, ϕ::Real)
    (-1.0)^m*sf_legendre_Plm(l, abs(m), cos(θ))*ℯ^(im*m*ϕ)
end


# ╔═╡ 778c4fa2-68c0-494f-ae22-477189a27f2b
# The Radial dependence
function R(n::Int, l::Int, ρ::Real)
    sf_laguerre_n(n-l-1, 2*l+1, ρ)*ℯ^(-ρ/2)*ρ^l
end


# ╔═╡ cf4d7a50-afea-4f10-b08d-0f0150b7da7a
# A normalization: This is dependent on the choice of polynomial representation
function norm(n::Int, l::Int)
    sqrt((2/n)^3 * factorial(n-l-1)/(2n*factorial(n+l)))
end

# ╔═╡ d3ff17f0-3dd6-4ffe-a045-5b573aec02a5
# Generates an Orbital Funtion of (r, θ, ϕ) for a specificied n, l, m.
function Orbital(n::Int, l::Int, m::Int)
    # we make sure l and m are within proper bounds
    if l > n || abs(m) > l
        throw(DomainError())
    end
    Ψ(ρ, θ, ϕ) = norm(n, l) * R(n, l, ρ) * abs(Yml(m, l, θ, ϕ))
    Ψ
end

# ╔═╡ 94158386-447f-40cd-a321-8b333053d558
function CarttoSph(x::Array, y::Array, z::Array)
    r = sqrt.(x.^2+y.^2+z.^2)
    θ = acos.(z./r)
    ϕ = atan.(y./x)
    r, θ, ϕ
end

# ╔═╡ ad5ffb61-b2cc-499a-87a4-ad71833de766
function calculate_electronic_density(n, l, m)
    N = 50
    r = 1e-9
    s = LinRange(-r, r, N)
    x, y, z = meshgrid(s, s, s)

    r, θ, ϕ = CarttoSph(x, y, z)
    Ψ = Orbital(n, l, m)

    Ψv = zeros(Float32, N, N, N)
    for i in 1:N
        for j in 1:N
            for k in 1:N
                Ψv[i, j, k] = abs(Ψ(ρ(r[i, j, k], n), θ[i, j, k], ϕ[i, j, k]))
            end
        end
    end

    (Ψv.-minimum(Ψv))./(maximum(Ψv).-minimum(Ψv))
end

# ╔═╡ a4c51114-4bf9-4d40-b123-1629a3be54e1
@bind Ψ Select(["2,0,0", "3,0,0", "2,1,0", "3,1,0", "3,1,1", "2,1,1", "3,2,0", "3,2,1", "3,2,2", "4,0,0", "4, 1,0", "4,2,0", "4,2,1", "4,2,2", "4,3,0", "4,3,1", "4,3,2", "4,3,3"], default="3,2,0")

# ╔═╡ 11cfffdf-91d6-4909-bb59-e8d12a95e5e8
@bind ϕ Slider(0:360, default=30)

# ╔═╡ 9899f86c-2fba-4d72-abab-acbef1dc6988
@bind iso Slider(0.1:0.05:0.8, default=0.2)

# ╔═╡ 16697f21-f879-48d1-ad41-f39e1dde5830
begin
    n, m, l = parse.(Int, split(Ψ, ','))
    Ψv = calculate_electronic_density(n, m, l)
    isosurface(Ψv, isovalue=iso, rotation=ϕ)
end

# ╔═╡ Cell order:
# ╠═5323b5ac-0c51-4952-8f27-4f489c1f2d1a
# ╠═d8aeb9f4-990c-11eb-0dbb-078cda4928d5
# ╠═6127fb6a-22fc-4f35-8228-cc06ffebf9c0
# ╠═7aa443bd-b706-41e2-bdc8-0d8c10c99b02
# ╠═778c4fa2-68c0-494f-ae22-477189a27f2b
# ╠═cf4d7a50-afea-4f10-b08d-0f0150b7da7a
# ╠═d3ff17f0-3dd6-4ffe-a045-5b573aec02a5
# ╠═94158386-447f-40cd-a321-8b333053d558
# ╠═ad5ffb61-b2cc-499a-87a4-ad71833de766
# ╠═a4c51114-4bf9-4d40-b123-1629a3be54e1
# ╠═11cfffdf-91d6-4909-bb59-e8d12a95e5e8
# ╠═9899f86c-2fba-4d72-abab-acbef1dc6988
# ╠═16697f21-f879-48d1-ad41-f39e1dde5830
