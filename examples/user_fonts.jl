ENV["GKS_FONT_DIRS"] = "/usr/local/gr/fonts"

const fonts = (
    "NimbusRomNo9L-Regu.pfb",       # 1: Times New Roman
    "NimbusRomNo9L-ReguItal.pfb",
    "NimbusRomNo9L-Medi.pfb",
    "NimbusRomNo9L-MediItal.pfb",
    "NimbusSanL-Regu.pfb",          # 5: Helvetica
    "NimbusSanL-ReguItal.pfb",
    "NimbusSanL-Bold.pfb",
    "NimbusSanL-BoldItal.pfb",
    "NimbusMonL-Regu.pfb",          # 9: Courier
    "NimbusMonL-ReguObli.pfb",
    "NimbusMonL-Bold.pfb",
    "NimbusMonL-BoldObli.pfb",
    "Symbola.ttf",                  # 13: Symbol
    "URWBookmanL-Ligh.pfb",         # 14: Bookman Light
    "URWBookmanL-LighItal.pfb",
    "URWBookmanL-DemiBold.pfb",
    "URWBookmanL-DemiBoldItal.pfb",
    "CenturySchL-Roma.pfb",         # 18: New Century Schoolbook Roman
    "CenturySchL-Ital.pfb",
    "CenturySchL-Bold.pfb",
    "CenturySchL-BoldItal.pfb",
    "URWGothicL-Book.pfb",          # 22: Avant Garde Book
    "URWGothicL-BookObli.pfb",
    "URWGothicL-Demi.pfb",
    "URWGothicL-DemiObli.pfb",
    "URWPalladioL-Roma.pfb",        # 26: Palatino
    "URWPalladioL-Ital.pfb",
    "URWPalladioL-Bold.pfb",
    "URWPalladioL-BoldItal.pfb",
    "URWChanceryL-MediItal.pfb",    # 30: Zapf Chancery
    "Dingbats-Regu.ttf",            # 31: Dingbats
)

using GR

selntran(0)
setcharheight(0.018)
settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)

y = 0.95
for fontname in fonts
  global y
  font = loadfont(fontname)
  settextfontprec(font, GR.TEXT_PRECISION_OUTLINE)
  if startswith(fontname, "Symbol")
    s = "ABCDEFGHIJKLMNOPQSTUVWXYZabcdefghijklmnopqstuvwxyz"
  elseif startswith(fontname, "Dingbats")
    y -= 0.015
    s = "!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNO\nPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
  else
    s = "The quick brown fox jumps over the lazy dog"
  end
  text(0.5, y, s)
  tbx, tby = inqtext(0.5, y, s)
  fillrect(tbx[1], tbx[2], tby[1], tby[3])
  y -= 0.03
end

updatews()
