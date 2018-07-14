#! /usr/bin/env ruby

require_relative 'beaotic/beaotic'

b = Beaotic::Instrument.new('xt808')
b.define_script

b.var_dump
b.print