import GR

import Random
srand(seed) = Random.seed!(seed)

function main()
    srand(37)
    y = randn(20, 500)

    GR.setviewport(0.1, 0.95, 0.1, 0.95)
    GR.setcharheight(0.020)
    GR.settextcolorind(82)
    GR.setfillcolorind(90)
    GR.setfillintstyle(1)

    for x in 1:5000
        GR.clearws()
        GR.setwindow(x, x+500, -200, 200)
        GR.fillrect(x, x+500, -200, 200)
        GR.setlinecolorind(0);  GR.grid(50, 50, 0, -200, 2, 2)
        GR.setlinecolorind(82); GR.axes(50, 50, x, -200, 2, 2, -0.005)
        y = hcat(y, randn(20))
        for i in 1:20
            GR.setlinecolorind(980 + i)
            s = cumsum(reshape(y[i,:], x+500))
            GR.polyline([x:x+500;], s[x:x+500])
        end
        GR.updatews()
    end
end

main()
