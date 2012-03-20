require 'rubygems'
require 'fftw3'
require 'ruby-audio'

require "util"

FRAME_STEPS = 128

target_filename = "AmenMono.wav"
size, info = save_params_for(target_filename)
puts size

target_spectra = spectra_for_soundfile(target_filename)
target_frame_width, target_frame_count = target_spectra.sizes

sample_filename = "snare1.wav"
sample_spectra = spectra_for_soundfile(sample_filename, target_spectra.sizes[1])
sample_fft = FFTW3.fft( sample_spectra )

out = []

100.times do |n|
  STDERR.puts "##{n}"

  target_fft = FFTW3.fft( target_spectra )
  corr = FFTW3.ifft(target_fft * sample_fft.conj).real
  corr_flat = []
  (0...corr.sizes[1]).each do |i|
    val = corr[i * corr.sizes[0]]
    corr_flat << val
  end

  corr_max = corr_flat.max
  STDERR.puts "##{corr_max}"
  break if corr_max <= 0

  peak = corr_flat.index( corr_max )
  STDERR.puts "#{peak * FRAME_STEPS} #{sample_filename}"
  out << [peak * FRAME_STEPS, sample_filename]
  out.sort!

  File.open("output.txt", "w") do |f|
    f.puts size
    out.each do |out_line|
      f.puts out_line.join(" ")
    end
  end

  sample_frame_width, sample_frame_count = sample_spectra.sizes

  sample_frame_count.times do |frame_number|
    frame_in_target = peak + frame_number
    break if frame_in_target >= target_frame_count
    sample_frame_width.times do |within_frame|
      was = target_spectra[within_frame, frame_in_target]
      minus = sample_spectra[within_frame, frame_number]
      target_spectra[within_frame, frame_in_target] = [0, was - minus].max
    end
  end
end

out.each do |out_line|
  puts out_line.join(" ")
end
