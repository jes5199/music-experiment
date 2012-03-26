require 'rubygems'
require 'fftw3'
require 'ruby-audio'

require "util"

def make_tone_chop( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  (frames_per_second * duration).to_i.times do |n|
    yield Math.sin(n * step)
  end
end

def make_tone( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  (cycles * cycles_per_tau).to_i.times do |n|
    yield Math.sin(n * step)
  end
end

def make_tone_bounce( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  frequency /= 2
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  (cycles * cycles_per_tau).to_i.times do |n|
    yield Math.sin(n * step).abs
  end
end

def make_square_wave( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  (cycles * cycles_per_tau).to_i.times do |n|
    if Math.sin(n * step) > 0
      yield 1
    else
      yield -1
    end
  end
end

def make_sawtooth_wave( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  saw_step = 1.0 / (cycles_per_tau / 2)

  (cycles * cycles_per_tau).to_i.times do |n|
    x = n % cycles_per_tau
    section = (x / (cycles_per_tau / 2)).floor
    case section
    when 0
      yield x * saw_step
    when 1
      yield( (x - cycles_per_tau) * saw_step)
    else
      raise section.inspect
    end
  end
end

def make_triangle_wave( frequency = 440.0, duration = 1.0, frames_per_second = 44100 )
  cycles_per_tau = frames_per_second / frequency.to_f
  tau = Math::PI * 2
  step = tau / cycles_per_tau

  cycles = (frequency * duration).ceil

  triangle_step = 1.0 / (cycles_per_tau / 4)

  (cycles * cycles_per_tau).to_i.times do |n|
    x = n % cycles_per_tau
    section = (x / (cycles_per_tau / 4)).floor
    case section
    when 0
      yield x * triangle_step
    when 1, 2
      yield( 1.0 - ((x - (cycles_per_tau / 4)) * triangle_step) )
    when 3
      yield( (x - cycles_per_tau) * triangle_step)
    else
      raise section.inspect
    end
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

result_buffer = RubyAudio::Buffer.new("float", 44100 * 60, 1)
i = 0

#[:make_tone, :make_tone_bounce, :make_triangle_wave, :make_sawtooth_wave, :make_square_wave].each do |method|
[:make_tone].each do
  c_major_scale.each do |note|
    f = 440 * (2 ** (note/12.0))
    p f
    send(method, f, duration_of_one_beat_at_bpm(120) / 2) do |val|
      result_buffer[i] = val * strength
      #puts( " " * ((val + 1) * 10) + val.inspect) rescue puts val.inspect
      i += 1
    end
  end
end
info = RubyAudio::SoundInfo.new :channels => 1, :samplerate => 44100, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16
buffer_to_file(result_buffer, "beep.wav", info)
