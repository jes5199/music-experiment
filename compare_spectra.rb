require 'rubygems'
require 'fftw3'
require 'ruby-audio'
require 'algorithms'

FRAME_STEPS = 128

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

target_filename = "AmenMono.wav"
frames_per_second = frames_per_second_for_sound(target_filename)
target_spectra = spectra_for_soundfile(target_filename)
target_fft = FFTW3.fft( target_spectra )

sample_filename = "snare1.wav"
sample_spectra = spectra_for_soundfile(sample_filename, target_spectra.sizes[1])

sample_fft = FFTW3.fft( sample_spectra )

corr = FFTW3.ifft(target_fft * sample_fft.conj).real
corr_flat = []
(0...corr.sizes[1]).each do |i|
  val = corr[i * corr.sizes[0]]
  corr_flat << val
end

steps_per_second = (frames_per_second.to_f / FRAME_STEPS)

peaks = []
window_size =  steps_per_second / 20
blanks = [0] * (window_size / 2)
index = 0
(blanks + corr_flat + blanks).each_cons(window_size) do |window|
  if window[ window_size / 2 ] == window.max
    raise "oops" if window[ window_size / 2 ] != corr_flat[index]
    peaks << index
  end
  index += 1
end

size, info = save_params_for(target_filename)
result_buffer = RubyAudio::Buffer.new("float", size, 1)

sample = RubyAudio::Sound.open(sample_filename)
sample_data = RubyAudio::Buffer.new("float", sample.info.frames, 1)
sample.read(sample_data)

p peaks

sounding = []
size.times do |i|
  time = i / frames_per_second.to_f
  if peaks[0] and (peaks[0] * FRAME_STEPS) == i
    p time

    sounding << [i, sample_data]
    peaks.shift
  end

  sounding.reject! do |n, data|
    (i-n) >= sample.info.frames
  end

  if sounding.length > 0
    value = sounding.map { |n, data| data[i-n] }.inject(:+)
    result_buffer[i] = value
  end
end

buffer_to_file(result_buffer, "output.wav", info)
