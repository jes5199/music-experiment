require 'rubygems'
require 'ruby-audio'

def read_data( sample_filename )
  sample = RubyAudio::Sound.open(sample_filename)
  sample_data = RubyAudio::Buffer.new("float", sample.info.frames, 1)
  sample.read(sample_data)
  return sample_data
end

def buffer_to_file( buffer, filename, info)
  output = RubyAudio::Sound.new(filename, "w", info)
  output.write(buffer)
  output.close
end

def get_next_sound
  if ARGF.eof?
    next_sound = nil
  else
    next_sound_frame, next_sound_file_name = ARGF.readline.split(/\s+/)
    next_sound = [ next_sound_frame.to_i, next_sound_file_name ]
  end
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
