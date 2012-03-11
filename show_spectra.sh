mkdir -p images && ruby spectra.rb $1 && ruby view_spectra.rb spectra/$1.spectra > images/$1.pgm && convert images/$1.pgm -flip -transverse images/$1.png && open images/$1.png 
