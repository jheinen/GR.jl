using GR
using LaTeXStrings

hor_align = Dict("Left" => 1, "Center" => 2, "Right" => 3)
vert_align = Dict("Top" => 1, "Cap" => 2, "Half" => 3, "Base" => 4, "Bottom" => 5)

selntran(0)
setcharheight(0.018)
settextfontprec(232, 3)

for angle in 0:360

  setcharup(sin(-angle * pi/180), cos(-angle * pi/180))
  setmarkertype(GR.MARKERTYPE_SOLID_PLUS)
  setmarkercolorind(4)
  clearws()

  for halign in keys(hor_align)
    for valign in keys(vert_align)
      settextalign(hor_align[halign], vert_align[valign])
      x = -0.1 + hor_align[halign] * 0.3;
      y = 1.1 - vert_align[valign] * 0.2;
      s = L"1+\frac{1+\frac{a}{b}}{1+\frac{1}{1+\frac{1}{a}}}"
      mathtex(x, y, s)
      tbx, tby = inqmathtex(x, y, s)
      fillarea(tbx, tby)
      polymarker([x], [y])
    end
  end

  updatews()
end
