require 'erb'
require 'yaml'
require 'pp'
require_relative 'lib-ksp.rb'

def developer_name
	'Henrik Jensen'
end

debug = true

@conf = parse_config
# @printable_conf = pp @conf

# template = ERB.new(File.new("template.erb").read)
# puts template.result(binding)

class KeyGroup    
    attr_writer :panels

    def initialize
        @panels = []
    end
    def panels
        @panels
    end
end

class UiPanel
    attr_writer :knobs

    def initialize
        @knobs = []
    end
    def knobs
        @knobs
    end
end

class UiKnob
    attr_reader :options

    def initialize(options = {})
        @options = options
    end
        
    def declare
        "declare ui_slider #{options[:name]} (#{options[:min_val]}, #{options[:max_val]})"
    end
end

key_groups = []
# declare variables functions and callbacks
@conf[:key_groups].each do |key_group|
    key_groups << KeyGroup.new
    key_group[:panels].each do |panel|
        key_groups.last.panels << UiPanel.new
        panel[:knobs].each do |knob|
            knob_options = {
                name: "$knob_#{key_group[:name]}_#{panel[:name]}_#{knob[:name]}",
                min_val: knob[:min_val],
                max_val: knob[:max_val],
                default_val: knob[:default_val]
            }
            key_groups.last.panels.last.knobs << UiKnob.new(knob_options)
        end
    end
end

key_groups.each do |key_group|
    key_group.panels.each do |panel|
        panel.knobs.each do |knob|
            puts knob.declare
        end
    end
end



