using GR

function hopalong(num, a, b, c)
    
    x::Float64, y::Float64 = 0, 0
    u, v, d = Float64[], Float64[], Float64[]
    
    for i = 1:num
        xx = y - sign(x) * sqrt(abs(b*x - c)); yy = a - x; x = xx; y = yy;
        push!(u, x); push!(v, y); push!(d, sqrt(x^2 + y^2))
    end
    setborderwidth(0)
    scatter(u,  v,  ones(num), d,  colormap=GR.COLORMAP_TERRAIN, title="Orbit of Hopalong attractor, num=$num, a=$a, b=$b, c=$c")
end

hopalong(1_000_000, 17.0, 0.314, 0.7773)
