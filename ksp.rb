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

template = ERB.new(File.new("template.erb").read)
puts template.result(binding)

