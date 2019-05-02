using GR
inline("iterm", false)

x = collect(0:0.01:2*pi)
for i = 1:100
    plot(x, sin.(x .+ i / 10.0))
end

