ENV["GKS_ENCODING"] = "utf8"

import GR

GR.selntran(0)
GR.setcharheight(0.024)

function main()
    GR.settextfontprec(2, 0)
    y = 0
    for i in 0:1
        GR.text(0.05, 0.85-y, " !\"#\$\$%&'()*+,-./")
        GR.text(0.05, 0.80-y, "0123456789:;<=>?")
        GR.text(0.05, 0.75-y, "@ABCDEFGHIJKLMNO")
        GR.text(0.05, 0.70-y, "PQRSTUVWXYZ[\\]^_")
        GR.text(0.05, 0.65-y, "`abcdefghijklmno")
        GR.text(0.05, 0.60-y, "pqrstuvwxyz{|}~ ")

        GR.text(0.5, 0.85-y, " ¡¢£¤¥¦§¨©ª«¬­®¯")
        GR.text(0.5, 0.80-y, "°±²³´µ¶·¸¹º»¼½¾¿")
        GR.text(0.5, 0.75-y, "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ")
        GR.text(0.5, 0.70-y, "ÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß")
        GR.text(0.5, 0.65-y, "àáâãäåæçèéêëìíîï")
        GR.text(0.5, 0.60-y, "ðñòóôõö÷øùúûüýþÿ")

        GR.settextfontprec(233, 3)
        y = 0.4
    end
    GR.updatews()
end

main()
