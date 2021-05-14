import PortAudio, FileIO
using GR
using FFTW

function play(c::Channel)
  data, = FileIO.load("Monty_Python.wav")
  stream = PortAudio.PortAudioStream(0, 1)
  spectrum = zeros(Int32, 300, 225)

  offset = 1
  while offset + 1024 < length(data)
    amplitudes = data[offset:offset+1024]
    offset += 1024

    PortAudio.write(stream, amplitudes)

    power = log.(abs.(fft(float(amplitudes))) .+ 1) * 50
    spectrum[1, :] = round.(Int, power[1:225])
    spectrum = circshift(spectrum, [-1, 0])

    put!(c, spectrum')
  end
  put!(c, nothing)
end

function main()
  c = Channel(0)
  task = @task play(c::Channel)
  bind(c, task)
  schedule(task)
  start = time_ns()

  while isopen(c)
    spectrum = take!(c)
    if spectrum === nothing
      break
    end

    if time_ns() - start > 20 * 1000000   # 20ms
      imshow(spectrum, colormap=-13, yflip=true)

      start = time_ns()
    end
  end
end

main()
