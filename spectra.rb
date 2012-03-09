require 'rubygems'
require 'fftw3'
require 'ruby-audio'
require 'fileutils'

def spectrogram(data, window = 256, step = 1)
  i = -1
  r = []
  data.each_cons(window){ |selection|
    i+=1 ; i %= step
    next if i != 0
    r << FFTW3.fft( selection )
  }
  return r
end


input_filename = ARGV[0]

FileUtils.mkdir_p("spectra")
spectra_filename = "spectra/#{input_filename}.spectra"

input_sound = RubyAudio::Sound.open(input_filename)
frames_per_second = input_sound.info.samplerate
input_data = input_sound.read(:float, frames_per_second * 20)
spectra = spectrogram( input_data )

File.open(spectra_filename, "w") do |f|
  f.write([spectra[0].size].pack("Q"))
  spectra.each do |time_slice|
    f.write(time_slice.real.to_s)
  end
end

