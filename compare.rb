require 'rubygems'
require 'fftw3'
require 'ruby-audio'

target = RubyAudio::Sound.open("AmenMono.wav")
frames_per_second = target.info.samplerate

sample = RubyAudio::Sound.open("snare1.wav")

target_data = target.read(:float, frames_per_second * 20)
sample_data = RubyAudio::Buffer.new("float", target_data.size, 1)
sample.read(sample_data)
sample_data[target_data.real_size - 1] = 0

target_fft = FFTW3.fft( target_data.entries )
sample_fft = FFTW3.fft( sample_data.entries )

corr = FFTW3.ifft(target_fft * sample_fft.conj)

max = 0
corr.each{|a| max = a.real.abs if a.real > max }

i = -1
corr.each do |a|
  i += 1
 #if (a.real.abs * 100 / max) > 75
 #  p (i / target.info.samplerate.to_f)
 #end
  p a.real
end

# TODO: find the peaks

#require 'ruby-debug'; debugger; true #DEBUG!
