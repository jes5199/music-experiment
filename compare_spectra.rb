require 'rubygems'
require 'fftw3'
require 'ruby-audio'
require 'algorithms'

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

def fps_for_soundfile(filename)
  sound = RubyAudio::Sound.open(filename)
  frames_per_second = sound.info.samplerate
  return frames_per_second
end

target_filename = "AmenMono.wav"
target_spectra = spectra_for_soundfile(target_filename)
target_fft = FFTW3.fft( target_spectra )
p target_spectra
p target_fft.sizes
p target_fft

sample_filename = "snare1.wav"
sample_spectra = spectra_for_soundfile(sample_filename, target_spectra.sizes[1])

sample_fft = FFTW3.fft( sample_spectra )
p sample_spectra
p sample_fft.sizes
p sample_fft

corr = FFTW3.ifft(target_fft * sample_fft.conj).real
p corr.sizes
(0...corr.sizes[1]).each do |i|
  print corr[i * corr.sizes[0]], " "
end
puts

heap = Containers::MaxHeap.new
