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


key_groups = []
# declare variables functions and callbacks
@conf[:key_groups].each do |key_group|
    key_groups << KeyGroup.new
    key_group[:panels].each do |panel|
        key_groups.last.panels << UiPanel.new
        panel[:knobs].each_with_index do |knob, idx|
            knob_options = {
                key_group_name: key_group[:name],
                panel_name: panel[:name],
                knob_idx: idx
            }
            key_groups.last.panels.last.knobs << UiKnob.new(knob.merge(knob_options))
        end
    end
end

puts "on init"
puts "  declare $mod_idx := 0"
key_groups.each do |key_group|
    key_group.panels.each do |panel|
        panel.knobs.each do |knob|
            puts "  " + knob.declare
        end
    end
end
puts "end on"

key_groups.each do |key_group|
    key_group.panels.each do |panel|
        panel.knobs.each do |knob|
            puts knob.function
        end
    end
end


key_groups.each do |key_group|
    key_group.panels.each do |panel|
        panel.knobs.each do |knob|
            puts knob.callback
        end
    end
end





