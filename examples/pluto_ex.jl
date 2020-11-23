### A Pluto.jl notebook ###
# v0.12.11

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 1b8554d8-fd89-11ea-3760-d960e6f55ebd
begin
	using SpecialFunctions
	x = 0:0.1:15
	j0, j1, j2, j3 = [besselj.(order, x) for order in 0:3]
end

# ╔═╡ 05ec2818-fd89-11ea-3da8-23ea406ba0da
begin
	ENV["GRDISPLAY"] = "pluto"
	using GR
	GR.js.init_pluto()
end

# ╔═╡ 6a7c464e-fd8b-11ea-042f-cfbcaddf2d0e
begin
	using PlutoUI
	@bind xmax Slider(5:15)
end

# ╔═╡ 25f44cb2-fd89-11ea-1bfb-ad13a07d717e
plot(x, j0, x, j1, x, j2, x, j3,
     labels=["J_0", "J_1", "J_2", "J_3"], location=11, xlim=(0, xmax))

# ╔═╡ Cell order:
# ╠═1b8554d8-fd89-11ea-3760-d960e6f55ebd
# ╠═05ec2818-fd89-11ea-3da8-23ea406ba0da
# ╠═6a7c464e-fd8b-11ea-042f-cfbcaddf2d0e
# ╠═25f44cb2-fd89-11ea-1bfb-ad13a07d717e
