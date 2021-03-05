using WAV
using GR

file = joinpath(dirname(Base.find_package("GR")), "..", "examples", "Monty_Python.wav")
y, fs = WAV.wavread(file)

shade(y, colormap=-GR.COLORMAP_BLUESCALE, ylim=(-1,1))
