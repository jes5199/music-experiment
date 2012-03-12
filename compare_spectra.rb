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

target_filename = "AmenMono.wav"
frames_per_second = frames_per_second_for_sound(target_filename)
target_spectra = spectra_for_soundfile(target_filename)
target_fft = FFTW3.fft( target_spectra )

sample_filename = "snare1.wav"
sample_spectra = spectra_for_soundfile(sample_filename, target_spectra.sizes[1])

sample_fft = FFTW3.fft( sample_spectra )

heap = Containers::MaxHeap.new
corr = FFTW3.ifft(target_fft * sample_fft.conj).real
(0...corr.sizes[1]).each do |i|
  heap.push [ corr[i * corr.sizes[0]], i]
end

score, index = heap.max
time = (index * FRAME_STEPS) / frames_per_second.to_f


