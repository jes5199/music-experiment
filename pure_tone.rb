require 'rubygems'
require 'fftw3'
require 'ruby-audio'

require "util"

def make_tone( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  (frames_per_second * duration).to_i.times do |n|
    yield Math.sin(n * step)
  end
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

result_buffer = RubyAudio::Buffer.new("float", 44100 * 13, 1)
i = 0
[3,5,7,8,10,12,14,15].each do |note|
  f = 220 * (2 ** (note/12.0))
  p f
  make_tone(f) do |val|
    result_buffer[i] = val
    i += 1
  end
end
info = RubyAudio::SoundInfo.new :channels => 1, :samplerate => 44100, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16
buffer_to_file(result_buffer, "beep.wav", info)
