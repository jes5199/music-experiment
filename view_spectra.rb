require 'rubygems'

spectra_filename = ARGV[0]
scaling = 1.0

file_size = File.size(spectra_filename)
n = 100
puts "P3"
File.open(spectra_filename) do |f|
  frame_length = f.read(64 / 8).unpack("Q").first
  height = ( (file_size / (64/8)) - 1 ) / frame_length
  puts "#{frame_length/2} #{height}"
  puts 255
  while ! f.eof?
    frame = f.read(frame_length * 64 / 8).unpack("D*")
    i = 0
    frame.each do |val|
      break if i >= frame.length/2
      i += 1
      val = val.abs
      value = (((val * scaling) + 0) * (256 * 3) ).to_i
      blue = [[value, 0].max, 255].min
      green = [[value - 256, 0].max, 255].min
      red = [[value - 256*2, 0].max, 255].min
      [red, green, blue].each do |v|
        print("%-4d" % v)
      end
    end
    puts
  end
end

