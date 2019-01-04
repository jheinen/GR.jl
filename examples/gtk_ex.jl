using Gtk.ShortNames
using Printf
import GR

function paint(w)
    ctx = Gtk.getgc(w)
    h = Gtk.height(w)
    w = Gtk.width(w)

    if !Sys.isapple()
        Gtk.select_font_face(ctx, "Sans",
                             Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL);
        Gtk.move_to(ctx, 15, 15)
        Gtk.set_font_size(ctx, 14)
        Gtk.show_text(ctx, "Contour Plot using Gtk ...")
    end

    ENV["GKS_WSTYPE"] = "142"
    ENV["GKSconid"] = @sprintf("%lu", UInt64(ctx.ptr))

    xd = -2 .+ 4 .* rand(100)
    yd = -2 .+ 4 .* rand(100)
    zd = [xd[i] * exp(-xd[i]^2 - yd[i]^2) for i = 1:100]

    GR.setviewport(0.15, 0.95, 0.1, 0.9)
    GR.setwindow(-2, 2, -2, 2)
    GR.setspace(-0.5, 0.5, 0, 90)
    GR.setmarkersize(1)
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.setcharheight(0.024)
    GR.settextalign(2, 0)
    GR.settextfontprec(3, 0)

    x, y, z = GR.gridit(xd, yd, zd, 200, 200)
    levels = LinRange(-0.5, 0.5, 20)
    GR.contourf(x, y, levels, z, 0)
    GR.polymarker(xd, yd)
    GR.settextfontprec(1, 2)
    GR.axes(0.25, 0.25, -2, -2, 2, 2, 0.01)

    GR.updatews()
end

win = Gtk.GtkWindow("Gtk", 500, 500)
canvas = Gtk.GtkCanvas()
Gtk.push!(win, canvas)

Gtk.draw(paint, canvas)
Gtk.showall(win)

if !isinteractive()
    c = Condition()
    signal_connect(win, :destroy) do widget
        notify(c)
    end
    wait(c)
end
