spectra_filename = ARGV[0]

File.open(spectra_filename) do |f|
  frame_length = f.read(64 / 8).unpack("Q").first
  p frame_length
  while ! f.eof?
    frame = f.read(frame_length * 64 / 8).unpack("D*")
    p frame[0..5]
  end
end

