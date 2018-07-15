module Beaotic

  require 'time'
  require 'yaml'
  require 'pp'

  $LOAD_PATH.unshift './ksp/lib/'
  require 'ksp'
  require_relative './instrument'
  require_relative './knob'
  require_relative './diode'
  require_relative './button'
  require_relative './key'
  require_relative './image'
  require_relative './key_group'
  require_relative './main_panel'
  require_relative './mix_panel'
  require_relative './mix_channel'
end
