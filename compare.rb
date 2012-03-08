require 'rubygems'
require 'fftw3'
require 'ruby-audio'
require 'algorithms'

def find_max(c)
  max_i = -1
  max = 0
  i = 0
  c.each do |a|
    if a.real > max
      max = a.real.abs
      max_i = i
    end
    i += 1
  end
  return max_i
end

def delay_fft( delay, fft_data )
  r = NArray.new("complex", fft_data.size)

  _D = delay
  _N = fft_data.size
  k = 0 # fft frame number

  fft_data.each do |f|
    r[k] = f * ( Math::E ** Complex(0, (-2 * Math::PI * k * _D / _N)) )
    k += 1
  end

  return r
end

def fft_to_file( fft, filename, size, info )
  result_data = FFTW3.ifft( fft )
  data_to_file( result_data, filename, size, info, result_data.size )
end

def data_to_file( data, filename, size, info, scale )
  result_buffer = RubyAudio::Buffer.new("float", size, 1)
  i = 0
  data.each do |r|
    result_buffer[i] = (r.respond_to?(:real) ? r.real : r.to_f) / scale
    i += 1
  end
  output = RubyAudio::Sound.new(filename, "w", info)
  output.write(result_buffer)
  output.close
end


target = RubyAudio::Sound.open("AmenMono.wav")
frames_per_second = target.info.samplerate
target_data = target.read(:float, frames_per_second * 20)
target_fft = FFTW3.fft( target_data.entries )

heap = Containers::MaxHeap.new
inhibitions = {}
ffts_by_name = {}

["snare1.wav", "crash.wav"].each do |sample_name|
  puts sample_name
  sample = RubyAudio::Sound.open(sample_name)
  sample_data = RubyAudio::Buffer.new("float", target_data.size, 1)
  sample.read(sample_data)
  sample_length = sample_data.real_size
  sample_data[target_data.real_size - 1] = 0

  sample_fft = FFTW3.fft( sample_data.entries )
  ffts_by_name[sample_name] = sample_fft

  corr = FFTW3.ifft(target_fft * sample_fft.conj)

  window_size = (frames_per_second / 10)

  local_maximum = -1
  i = -1
  corr.each do |x| i+=1;
    if local_maximum < (i - window_size) && local_maximum >= 0
      value = corr[i].real
      if value > 0
        p([ local_maximum / frames_per_second.to_f, value] )
        heap.push [value, local_maximum, sample_name, sample_fft]
      end
      local_maximum = -1
    end

    if corr[i] > corr[local_maximum]
      local_maximum = i
    end
  end

  inhibitions[sample_name] = []
end

sample_sample_correlations = {}
ffts_by_name.each do |sample1_name, sample1_fft|
  sample_sample_correlations[sample1_name] = {}
  ffts_by_name.each do |sample2_name, sample2_fft|
    puts "#{sample1_name} vs #{sample2_name}"
    corr = FFTW3.ifft(sample1_fft * sample2_fft.conj)
    sample_sample_correlations[sample1_name][sample2_name] = corr
  end
end

result_fft = NArray.new("complex", target_fft.size)

n = 0
while heap.max
  p heap.size
  n += 1
  score, offset, sample_name, sample_fft = heap.pop
  p([ offset / frames_per_second.to_f, sample_name])
  delayed_sample_fft = delay_fft( offset, sample_fft )
  result_fft += delayed_sample_fft
  new_heap = Containers::MaxHeap.new
  while heap.max
    score2, offset2, sample2_name, sample2_fft = heap.pop
    inhibit = sample_sample_correlations[sample_name][sample2_name][ offset2 - offset ].real
    if inhibit > 0
      puts "inhibits #{sample2_name} at #{offset2} by #{inhibit}"
      score2 = score2 - inhibit
      break if score2 <= 0
    end
    new_heap.push [score2, offset2, sample2_name, sample2_fft]
  end
  heap = new_heap
  fft_to_file( result_fft,   "partials/output.#{'%05d' % n}.wav", target_data.size, target.info )
end

fft_to_file( result_fft,   "output.wav", target_data.size, target.info )
