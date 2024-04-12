using DSP
using GR

fs = 96_000
tmax = (8192 - 1) / fs

t = 0:1/fs:tmax
N = length(t)
signal = randn.(N) # noise
for f in (261.3, 329.63, 392.00)
    global signal
    signal = signal .+  sin.(2π * f .* t)
end

responsetype = Lowpass(500; fs)
designmethod = FIRWindow(hanning(128; zerophase=false))
f = filt(digitalfilter(responsetype, designmethod), signal)

plot(t, f, title="Low-pass filtered signal")
