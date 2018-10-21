using GR

include("noise.jl")

const n = 100000
const radius = 200
const width, height = 500, 500
const length = 50
const scale = 0.005

function main()
    
    T = rand(n) * 2pi
    R = sqrt.(rand(n))
    X = R .* cos.(T)
    Y = R .* sin.(T)
    intensity = (1.001 .- sqrt.(X.^2 .+ Y.^2)) .^ 0.75
    X = X .* radius .+ div(width, 2)
    Y = Y .* radius .+ div(height, 2)
    
    w, h, I = readimage("julia-logo.png")
    P = zeros(UInt32, width, height)
    
    settextfontprec(128, 0)
    settextalign(2, 3)
    setcharheight(0.036)

    for time in 0:0.004:1
        P .= 0xffffffff
        cos_t = 1.5 * cos(2pi * time)
        sin_t = 1.5 * sin(2pi * time)
        for i in 1:n
            x, y = X[i], Y[i]
            dx = noise4(scale * x, scale * y, cos_t, sin_t, 2)
            dx *= intensity[i] * length
            dy = noise4(100 + scale * x, 200 + scale * y, cos_t, sin_t, 2)
            dy *= intensity[i] * length
            P[round(Int, x + dx), round(Int, y + dy)] = I[round(Int, x), round(Int, y)]
        end
        
        clearws()
        setviewport(0, 1, 0, 1)
        drawimage(0, 1, 0, 1, width, height, P)
        textext(0.5, -0.2 + 1.5*time, "Julia Noise\\n\\nMade with GR.jl\\n\\nOriginal idea by Necessary Disorder")
        updatews()
    end
end

main()
