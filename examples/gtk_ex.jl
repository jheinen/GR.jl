using Gtk.ShortNames, GtkReactive, Gtk.GConstants

using Printf
using GR

x = randn(1000000)
y = randn(1000000)

function plot(ctx, w, h)
    global sl

    ENV["GKS_WSTYPE"] = "142"
    ENV["GKSconid"] = @sprintf("%lu", UInt64(ctx.ptr))

    plt = gcf()
    plt[:size] = (w, h)
    nbins = sl.signal.value

    hexbin(x, y, nbins=nbins)
end

function draw(widget)
    ctx = Gtk.getgc(widget)
    w = Gtk.width(widget)
    h = Gtk.height(widget)

    Gtk.rectangle(ctx, 0, 0, w, h)
    Gtk.set_source_rgb(ctx, 1, 1, 1)
    Gtk.fill(ctx)

    plot(ctx, w, h)

    Gtk.select_font_face(ctx, "Sans", 0, 0)
    Gtk.move_to(ctx, 15, 15)
    Gtk.set_font_size(ctx, 14)
    Gtk.show_text(ctx, "Contour Plot using Gtk ...")
end

function resize_event(widget)
    ctx = Gtk.getgc(widget)
    h = Gtk.height(widget)
    w = Gtk.width(widget)

    Gtk.paint(ctx)
end

function motion_notify_event(widget::Gtk.GtkCanvas, event::Gtk.GdkEventMotion)
    @show event.x, event.y
end

win = Window("Gtk") |> (bx = Box(:v))
sl = slider(10:100)
push!(sl, 30)
canvas = Canvas(500, 500)
push!(bx, sl)
push!(bx, canvas)

Gtk.add_events(canvas, GConstants.GdkEventMask.POINTER_MOTION_HINT)
signal_connect(motion_notify_event, canvas, "motion-notify-event")

canvas.resize = resize_event
canvas.draw = draw

Gtk.showall(win)

if !isinteractive()
    c = Condition()
    signal_connect(win, :destroy) do widget
        notify(c)
    end
    wait(c)
end
