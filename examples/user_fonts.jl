download("https://gr-framework.org/downloads/gr-fonts.tgz", "fonts.tgz")
run(`tar xzf fonts.tgz`)
rm("fonts.tgz")

ENV["GKS_FONT_DIRS"] = joinpath(pwd(), "fonts", "urw-base35")

const fonts = ("Times Roman", "Times Italic", "Times Bold", "Times Bold Italic", "Helvetica", "Helvetica Oblique", "Helvetica Bold", "Helvetica Bold Oblique", "Courier", "Courier Oblique", "Courier Bold", "Courier Bold Oblique", "Bookman Light", "Bookman Light Italic", "Bookman Demi", "Bookman Demi Italic", "New Century Schoolbook Roman", "New Century Schoolbook Italic", "New Century Schoolbook Bold", "New Century Schoolbook Bold Italic", "Avantgarde Book", "Avantgarde Book Oblique", "Avantgarde Demi", "Avantgarde Demi Oblique", "Palatino Roman", "Palatino Italic", "Palatino Bold", "Palatino Bold Italic", "Zapf Chancery Medium Italica", "Zapf Dingbats")

using GR

selntran(0)
setcharheight(0.018)
settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)

y = 0.95
for fontname in fonts
  global y
  font = loadfont(fontname)
  settextfontprec(font, GR.TEXT_PRECISION_OUTLINE)
  text(0.5, y, "The quick brown fox jumps over the lazy dog")
  tbx, tby = inqtext(0.5, y, "The quick brown fox jumps over the lazy dog")
  fillrect(tbx[1], tbx[2], tby[1], tby[3])
  y -= 0.03
end

updatews()
