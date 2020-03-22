# Plot a real-time spectrogram
# see https://github.com/JuliaAudio/PortAudio.jl

using GR, PortAudio, SampledSignals, FFTW

const N = 1024
const stream = PortAudioStream(1, 0)
const buf = read(stream, N)
const fmin = 0Hz
const fmax = 10000Hz
const fs = Float32[float(f) for f in domain(fft(buf)[fmin..fmax])]

while true
    read!(stream, buf)
    plot(fs, abs.(fft(buf)[fmin..fmax]), xlim=(fs[1],fs[end]), ylim=(0,100))
end
