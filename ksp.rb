require 'erb'
require 'yaml'
require 'pp'
require_relative 'lib-ksp.rb'

def developer_name
	'Henrik Jensen'
end

debug = true

@conf = parse_config
puts @conf.inspect 
# @printable_conf = pp @conf

# template = ERB.new(File.new("template.erb").read)
# puts template.result(binding)


key_groups = []
# Popuate ruby elements
@conf[:key_groups].each do |key_group_conf|
    key_groups << Ksp::KeyGroup.new(key_group_conf)
    puts key_groups.last.name + "\n"    
end

# init callback - declare variables
puts "on init"
key_groups.each do |key_group|
    key_group.knobs.each do |knob|
        knob.declare.split(/\n/).each do |statement|
            puts "  " + statement
        end
    end
end
puts "end on"

# declare user defined functions
key_groups.each do |key_group|
    puts key_group.functions
    # key_group.knobs.each do |knob|
    #     puts knob.function
    # end
end

# declare ui callbacks
key_groups.each do |key_group|
    key_group.knobs.each do |knob|
        puts knob.callback
    end
end

# declare midi callbacks




