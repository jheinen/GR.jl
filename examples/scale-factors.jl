using GR

const LINEWIDTH_TO_NDC = 1/500
const MARKERSIZE_TO_NDC =  500/6

function lines()
    y = 0.4
    for w in (1, 2, 5, 10, 20, 50)
        setlinewidth(w)
        polyline([0, 0.25], [y + w*0.5*LINEWIDTH_TO_NDC, y + w*0.5*LINEWIDTH_TO_NDC])
        y += 0.1
    end
end

function markers()
    setmarkertype(-1)
    setmarkercolorind(983)
    setbordercolorind(1)
    x = y = 0
    for s = (0.1, 0.2, 0.3, 0.4)
        x += s
        y = x
        setmarkersize(s * MARKERSIZE_TO_NDC)
        polymarker([x - 0.5*s], [y - 0.5*s])
   end
end

selntran(0)
grid(0.01, 0.01, 0, 0, 10, 10)

markers()
lines()

updatews()
