using Gtk4
using GR
using Printf

c = GtkCanvas()

function _plot(ctx, w, h)
    ENV["GKS_WSTYPE"] = "142"
    ENV["GKSconid"] = @sprintf("%lu", UInt64(ctx.ptr))
    plot(randn(10, 3), size=(w, h))
end

@guarded draw(c) do widget
    ctx = getgc(c)
    w = width(c)
    h = height(c)
    @show w, h
    rectangle(ctx, 0, 0, w, h)
    set_source_rgb(ctx, 1, 1, 1)
    fill(ctx)
    _plot(ctx, w, h)
end

win = GtkWindow("Gtk4 example", 600, 450)
win[] = c

e = GtkEventControllerMotion(c)

function on_motion(controller, x, y)
    win.title = @sprintf("(%g, %g)", x, y)
    reveal(c) # triggers a redraw
end

signal_connect(on_motion, e, "motion")
