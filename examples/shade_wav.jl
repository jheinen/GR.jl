using WAV
using GR

y, fs = WAV.wavread("Monty_Python.wav")

shade(y, colormap=-GR.COLORMAP_BLUESCALE, ylim=(-1,1))
