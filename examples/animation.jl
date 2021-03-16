ENV["GKS_WSTYPE"] = "mov"  # or "webm", "mp4"
ENV["GKS_VIDEO_OPTS"] = "600x450@25@2x"

using GR

x = LinRange(0, 2π, 200)
for i = 0:100
    plot(x, sin.(x .+ i / 10.0))
end
