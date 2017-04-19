import PortAudio, LibSndFile
import GR

function play()
  data = LibSndFile.load("Monty_Python.wav")
  stream = PortAudio.PortAudioStream(0, 1, blocksize=1024)
  spectrum = zeros(Int32, 250, 250)

  start = 1
  while start + 1024 < length(data)
    amplitudes = data[start:start+1024]
    start += 1024

    PortAudio.write(stream, amplitudes)

    power = log(abs(fft(float(amplitudes))) + 1) * 50
    spectrum[:, 1] = round(Int, power[1:250]) + 1000
    spectrum = circshift(spectrum, [0, -1])

    produce(spectrum)
  end
end

t = Task(play)
start = time_ns()

while !istaskdone(t)
  spectrum = consume(t)
  if spectrum == nothing
     break
  end

  if time_ns() - start > 20 * 1000000   # 20ms
    GR.clearws()
    GR.setcolormap(-113)
    GR.setviewport(0, 1, 0, 1)
    GR.cellarray(0, 1, 0, 1, 250, 250, reshape(rotr90(spectrum), 250 * 250))
    GR.updatews()

    start = time_ns()
  end
end
