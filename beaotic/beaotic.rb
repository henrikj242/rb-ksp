module Beaotic
  require 'time'
  require 'yaml'
  require 'pp'

  $LOAD_PATH.unshift './ksp/lib/'
  require 'ksp'
  require_relative './instrument'
  require_relative './knob'
  require_relative './fader'
  require_relative './diode'
  require_relative './button'
  require_relative './key'
  require_relative './image'
  require_relative './key_group'
  require_relative './main_panel'
  require_relative './mix_panel'
  require_relative './mix_channel'
  require_relative './wallpaper'

  # symbolize function Grapped from https://gist.github.com/Integralist/9503099
  # modified by myself to support Ranges
  def self.symbolize(obj)
    return obj.reduce({}) do |memo, (k, v)|
      memo.tap { |m| m[k.to_sym] = symbolize(v) }
    end if obj.is_a? Hash

    return obj.reduce([]) do |memo, v|
      memo << symbolize(v); memo
    end if obj.is_a? Array

    return obj.to_a.reduce([]) do |memo, v|
      memo << symbolize(v); memo
    end if obj.is_a? Range

    obj
  end

  def self.parse_config(conf_file)
    symbolize(YAML::load_file(conf_file))
  end

end
