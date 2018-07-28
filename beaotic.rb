#! /usr/bin/env ruby

# run this script from where the yml-file is located
# point the output to the where your nkr file gets its scripts from
# For example...
# ./beaotic.rb > ../WORK\ XT-808\ Kit/Resources/scripts/xt808.txt

require_relative 'beaotic/beaotic'

if ARGV[0] == 'img-txt'
  Beaotic::Image.new.generate_txt_files
  exit(0)
else
  b = Beaotic::Instrument.new('xt808')
  b.var_dump
  b.print
end


