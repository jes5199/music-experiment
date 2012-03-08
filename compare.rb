require 'rubygems'
require 'fftw3'
require 'ruby-audio'

def find_max(c)
  max_i = -1
  max = 0
  i = 0
  c.each do |a|
    if a.real > max
      max = a.real.abs
      max_i = i
    end
    i += 1
  end
  return max_i
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

def fft_to_file( fft, filename, size, info, scale )
  result_data = FFTW3.ifft( fft )
  data_to_file( result_data, filename, size, info, scale )
end

def data_to_file( data, filename, size, info, scale )
  result_buffer = RubyAudio::Buffer.new("float", size, 1)
  i = 0
  data.each do |r|
    result_buffer[i] = (r.respond_to?(:real) ? r.real : r.to_f) / scale
    i += 1
  end
  output = RubyAudio::Sound.new(filename, "w", info)
  output.write(result_buffer)
  output.close
end


target = RubyAudio::Sound.open("AmenMono.wav")
frames_per_second = target.info.samplerate

sample = RubyAudio::Sound.open("snare1.wav")

target_data = target.read(:float, frames_per_second * 20)
sample_data = RubyAudio::Buffer.new("float", target_data.size, 1)
sample.read(sample_data)
sample_data[target_data.real_size - 1] = 0

target_fft = FFTW3.fft( target_data.entries )
sample_fft = FFTW3.fft( sample_data.entries )

ifft_target_fft = FFTW3.ifft(target_fft)
(0...ifft_target_fft.size).each do |i|
  p([ target_data[i], (ifft_target_fft[i].real / 308112.0)]) if (target_data[i] - (ifft_target_fft[i].real / 308112.0)).abs > 0.00000001
end

#data_to_file( target_data, "Amen.ifft.wav", target_data.size, target.info, 308112.0 )
data_to_file( ifft_target_fft, "Amen.ifft.wav", target_data.size, target.info, 308112.0 )

result_fft = NArray.new("complex", target_fft.size)

p target_fft
1.times do
  corr = FFTW3.ifft(target_fft * sample_fft.conj)

  best_match = find_max(corr)
  p( best_match / frames_per_second.to_f )

  delayed_sample_fft = delay_fft( best_match, sample_fft )

  target_fft -= delayed_sample_fft
  result_fft += delayed_sample_fft

  p target_fft
end

fft_to_file( result_fft, "output.wav", target_data.size, target.info )
