require 'rubygems'
require 'fftw3'
require 'ruby-audio'

require "util"

def make_tone( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  (cycles * cycles_per_tau).to_i.times do |n|
    yield Math.sin(n * step)
  end
end

def duration_of_one_beat_at_bpm(n)
  60 / n.to_f
end

# 0 A
# 1 A#
# 2 B
# 3 C
# 4 C#
# 5 D
# 6 D#
# 7 E
# 8 F
# 9 F#
# 10 G
# 11 G#

c_major_scale = [-9,-7,-5,-4,-2,0,2,3]

strength = 0.75

result_buffer = RubyAudio::Buffer.new("float", 44100 * 13, 1)
i = 0
c_major_scale.each do |note|
  f = 440 * (2 ** (note/12.0))
  p f
  make_tone(f, duration_of_one_beat_at_bpm(120) / 2) do |val|
    result_buffer[i] = val * strength
    i += 1
  end
end
info = RubyAudio::SoundInfo.new :channels => 1, :samplerate => 44100, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16
buffer_to_file(result_buffer, "beep.wav", info)
