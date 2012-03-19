def read_spectra_from_file(spectra_filename, rows = 0)
  spectra = []
  frame_length = nil

  File.open(spectra_filename) do |f|
    frame_length = f.read(64 / 8).unpack("Q").first

    while ! f.eof?
      frame = NArray[ * f.read(frame_length * 64 / 8).unpack("D*") ]
      rows -= 1
      spectra << frame
    end
  end

  while rows > 0
    rows -= 1
    spectra << [0] * frame_length
  end

  return NArray[ *spectra ]
end

def spectra_for_soundfile(filename, rows = 0)
  sound = RubyAudio::Sound.open(filename)
  spectra_filename = "spectra/#{filename}.spectra"
  return read_spectra_from_file(spectra_filename, rows)
end

def frames_per_second_for_sound(filename)
  sound = RubyAudio::Sound.open(filename)
  return sound.info.samplerate
end

def fps_for_soundfile(filename)
  sound = RubyAudio::Sound.open(filename)
  frames_per_second = sound.info.samplerate
  return frames_per_second
end

def delay_fft( delay, fft_data )
  r = NArray.new("complex", fft_data.size)

  _D = delay
  _N = fft_data.size
  k = 0 # fft frame number

  fft_data.each do |f|
    r[k] = f * ( Math::E ** Complex(0, (-2 * Math::PI * k * _D / _N)) )
    k += 1
  end

  return r
end

def fft_to_file( fft, filename, size, info )
  result_data = FFTW3.ifft( fft )
  data_to_file( result_data, filename, size, info, result_data.size )
end

def data_to_file( data, filename, size, info, scale )
  result_buffer = RubyAudio::Buffer.new("float", size, 1)
  i = 0
  data.each do |r|
    result_buffer[i] = (r.respond_to?(:real) ? r.real : r.to_f) / scale
    i += 1
  end
  buffer_to_file( result_buffer, info )
end

def buffer_to_file( buffer, filename, info)
  output = RubyAudio::Sound.new(filename, "w", info)
  output.write(buffer)
  output.close
end

def save_params_for(sound_filename)
  sound = RubyAudio::Sound.open(sound_filename)
  [sound.info.frames, sound.info]
end


