#! /usr/bin/ruby
require 'time'
require 'yaml'
require 'pp'

require_relative 'beaotic/beaotic'

b = Beaotic::Instrument.new('xt808')

b.var_dump
b.print