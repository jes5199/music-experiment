require 'rubygems'
require 'ruby-audio'

require "util"

def get_next_sound
  line = nil
  begin
    if ARGF.eof?
      next_sound = nil
      return
    end
    line = ARGF.readline
  end while line =~ /^\s*#/

  next_sound_frame, next_sound_file_name = line.split(/\s+/)
  next_sound = [ next_sound_frame.to_i, next_sound_file_name ]
end

size = ARGF.readline.to_i
p size

result_buffer = RubyAudio::Buffer.new("float", size, 1)
FramesPerSecond = 44100

next_sound = get_next_sound

sounding = []
size.times do |i|
  time = i / FramesPerSecond.to_f
  while next_sound and next_sound[0] == i
    sounding << [i, read_data(next_sound[1])]
    p [time, next_sound[1]]

    next_sound = get_next_sound
  end

  sounding.reject! do |n, data|
    (i-n) >= data.size
  end

  if sounding.length > 0
    value = sounding.map { |n, data| data[i-n] }.inject(:+)
    result_buffer[i] = value
  end
end

info = RubyAudio::SoundInfo.new :channels => 1, :samplerate => FramesPerSecond, :format => RubyAudio::FORMAT_WAV|RubyAudio::FORMAT_PCM_16
buffer_to_file(result_buffer, "output.wav", info)
