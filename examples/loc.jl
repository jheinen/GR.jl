ENV["GKS_WSTYPE"] = "gksqt"

using GR

function simulation(c::Channel)
    z = peaks()
    for step = 10:0.1:100
        put!(c, z .* step)
    end
end

function main()

    mouse = Nothing
    rotation = 30
    tilt = 60

    for data in Channel(simulation)

        x, y, buttons = samplelocator()
        if mouse != Nothing && buttons != 0
            rotation += 50 * (x - mouse[1])
            tilt += 50 * (y - mouse[2])
        end
        mouse = [x, y]

        surface(data, rotation=rotation, tilt=tilt, title="Press MB1 to rotate, MB2 to quit")

        if buttons & 0x02 != 0
            break
        end
    end
end

main()

