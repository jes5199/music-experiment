require 'rubygems'

spectra_filename = ARGV[0]
scaling = 1.0

file_size = File.size(spectra_filename)
n = 100
puts "P3"
File.open(spectra_filename) do |f|
  frame_length = f.read(64 / 8).unpack("Q").first
  height = ( (file_size / (64/8)) - 1 ) / frame_length
  puts "#{frame_length} #{height}"
  puts 255
  while ! f.eof?
    frame = f.read(frame_length * 64 / 8).unpack("D*")
    frame.each do |val|
      value = (((val * scaling) + 1) * (256 * 1.5) ).to_i
      red = [[value, 0].max, 255].min
      green = [[value - 256, 0].max, 255].min
      blue = [[value - 256*2, 0].max, 255].min
      [red, green, blue].each do |v|
        print("%-4d" % v)
      end
    end
    puts
  end
end

