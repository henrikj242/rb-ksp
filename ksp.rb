require 'erb'
require 'yaml'
require 'pp'
require_relative 'lib'
$LOAD_PATH.unshift './ksp/lib/'
require 'ksp'

debug = true

project_name = ARGV[0]
conf_file = "#{File.dirname(__FILE__)}/#{project_name}"
@conf = parse_config(yaml_file(conf_file))

pp @conf if debug

key_groups = []
# Popuate ruby elements
@conf[:key_groups].each do |key_group_conf|
    key_groups << Ksp::KeyGroup.new(key_group_conf)
    puts "{{ Key group: #{key_groups.last.name} }} \n"
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




