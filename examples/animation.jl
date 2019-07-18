ENV["GKSwstype"] = "mp4"  # or "webm", "mov"

using GR

x = LinRange(0, 2π, 200)
for i = 0:100
    plot(x, sin.(x .+ i / 10.0))
end
