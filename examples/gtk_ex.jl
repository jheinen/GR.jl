using Gtk.ShortNames, Gtk.GConstants

using Printf
using GR

x = randn(1000000)
y = randn(1000000)

function plot(ctx, w, h)
    global sl

    ENV["GKS_WSTYPE"] = "142"
    ENV["GKSconid"] = @sprintf("%lu", UInt64(ctx.ptr))

    plt = kvs()
    plt[:size] = (w, h)
    nbins = Int64(Gtk.GAccessor.value(sl))

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
end

function resize_event(widget)
    ctx = Gtk.getgc(widget)
    h = Gtk.height(widget)
    w = Gtk.width(widget)

    Gtk.paint(ctx)
end

function motion_notify_event(widget::Gtk.GtkCanvas, event::Gtk.GdkEventMotion)
    Gtk.GAccessor.text(lb, @sprintf("(%g, %g)", event.x, event.y))
end

function value_changed(widget::Gtk.GtkScale)
    global canvas
    draw(canvas)
    reveal(canvas, true)
end

win = Window("Gtk") |> (bx = Box(:v))
lb = Label("(-, -)")
sl = Scale(false, 10, 100, 1)
Gtk.GAccessor.value(sl, 30)
canvas = Canvas(600, 450)
push!(bx, lb, sl, canvas)

signal_connect(motion_notify_event, canvas, "motion-notify-event")
signal_connect(value_changed, sl, "value_changed")

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
