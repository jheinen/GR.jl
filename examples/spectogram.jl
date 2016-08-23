if VERSION < v"0.4-"
  import AudioIO
  const pa = AudioIO
else
  import PortAudio, LibSndFile
end
import GR

function play()
  if VERSION < v"0.4-"
    f = pa.open("Monty_Python.wav")
    data = read(f)
    close(f)

    pa.Pa_Initialize()
    stream = pa.Pa_OpenDefaultStream(0, 1, pa.paInt16, 44100.0, 1024)
    pa.Pa_StartStream(stream)
  else
    data = LibSndFile.load("Monty_Python.wav")
    stream = PortAudio.PortAudioStream(0, 1, blocksize=1024)
  end
  spectrum = zeros(Int32, 250, 250)

  start = 1
  while start + 1024 < length(data)
    amplitudes = data[start:start+1024]
    start += 1024

    if VERSION < v"0.4-"
      pa.Pa_WriteStream(stream, amplitudes)
      amplitudes /= 22050.0
    else
      PortAudio.write(stream, amplitudes)
    end

    power = log(abs(fft(amplitudes)) + 1) * 50
    spectrum[:, 1] = round(Int, power[1:250]) + 1000
    spectrum = circshift(spectrum, [0, -1])

    produce(spectrum)
  end
end

t = Task(play)
start = time_ns()

while !istaskdone(t)
  spectrum = consume(t)

  if time_ns() - start > 20 * 1000000   # 20ms
    GR.clearws()
    GR.setcolormap(-113)
    GR.setviewport(0, 1, 0, 1)
    GR.cellarray(0, 1, 0, 1, 250, 250, reshape(rotr90(spectrum), 250 * 250))
    GR.updatews()

    start = time_ns()
  end
end
