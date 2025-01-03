using GR

charHeight = 0.2

selntran(0)
setcharheight(charHeight)
settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)

setlinecolorind(4)
polyline([0, 1], [0.5 - 0.5 * charHeight, 0.5 - 0.5 * charHeight])
polyline([0, 1], [0.5 + 0.5 * charHeight, 0.5 + 0.5 * charHeight])
setlinecolorind(2)
polyline([0, 1], [0.5 - 0.8 * charHeight, 0.5 - 0.8 * charHeight])
polyline([0, 1], [0.5 + 0.7 * charHeight, 0.5 + 0.7 * charHeight])

settextfontprec(232, GR.TEXT_PRECISION_OUTLINE)
text(0.5, 0.5, "Julia!")
tbx, tby = inqtext(0.5, 0.5, "Julia!")
fillrect(tbx[1], tbx[2], tby[1], tby[3])

updatews()

