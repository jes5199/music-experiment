require 'rubygems'

spectra_filename = ARGV[0]
scaling = 1.0

file_size = File.size(spectra_filename)
n = 100
puts "P2"
File.open(spectra_filename) do |f|
  frame_length = f.read(64 / 8).unpack("Q").first
  height = ( (file_size / (64/8)) - 1 ) / frame_length
  puts "#{frame_length} #{height}"
  puts 256
  while ! f.eof?
    frame = f.read(frame_length * 64 / 8).unpack("D*")
    frame.each do |val|
      grey = (((val * scaling) + 1) * 127).to_i
      grey = [grey, 255].min
      grey = [grey, 0].max
      print("%-4d" % grey)
    end
    puts
  end
end

