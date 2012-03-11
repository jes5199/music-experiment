require 'rubygems'
require 'fftw3'
require 'ruby-audio'
require 'fileutils'

def apply_hamming(buffer)
  buffer = buffer.dup
  (0...buffer.length).each do |i|
    buffer[i] *= 0.54 - (0.46 * Math.cos( 2 * Math::PI * (i / ((buffer.length - 1) * 1.0))));
  end
  return buffer
end

def spectrogram(data, window_size = 256, step_size = 128)
  i = -1
  r = []
  blank = [0.0] * window_size
  selection = blank.dup
  [blank, data, blank].each do |source|
    source.each do |frame|
      selection.shift
      selection.push frame
      i+=1 ; i %= step_size
      next if i != 0
      r << FFTW3.fft( apply_hamming(selection) )
    end
  end
  return r
end


input_filename = ARGV[0]

FileUtils.mkdir_p("spectra")
spectra_filename = "spectra/#{input_filename}.spectra"

exit if File.exists?(spectra_filename)

input_sound = RubyAudio::Sound.open(input_filename)
frames_per_second = input_sound.info.samplerate
input_data = input_sound.read(:float, frames_per_second * 20)
spectra = spectrogram( input_data, 4096, 128)

File.open(spectra_filename, "w") do |f|
  puts spectra[0].size
  f.write([spectra[0].size].pack("Q"))
  spectra.each do |time_slice|
    f.write(time_slice.real.to_s)
  end
end

