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

target = RubyAudio::Sound.open("AmenMono.wav")
frames_per_second = target.info.samplerate

sample = RubyAudio::Sound.open("snare1.wav")

target_data = target.read(:float, frames_per_second * 20)
sample_data = RubyAudio::Buffer.new("float", target_data.size, 1)
sample.read(sample_data)
sample_data[target_data.real_size - 1] = 0
p sample_data.real_size

target_fft = FFTW3.fft( target_data.entries )
sample_fft = FFTW3.fft( sample_data.entries )

# corr = FFTW3.ifft(target_fft * sample_fft.conj)

# best_match = find_max(corr)
# p best_match

sample_data2 = RubyAudio::Buffer.new("float", target_data.size, 1)
n = 1
sample_data.each{ |d|
  sample_data2[n % sample_data.real_size] = d
  n += 1
}
p sample_data2.real_size
sample2_fft = FFTW3.fft( sample_data2.entries )

(0..5).each do |n|
  p(sample2_fft[n] / sample_fft[n])
end

_D = 1 # delay
_N = sample_fft.size
k = 1 # fft frame number

Complex(0, (-2 * Math::PI * k * _D / _N))



# I want to rotate the sample's fft to be at the best_match offset
