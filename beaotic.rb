require 'erb'
require 'yaml'
require 'pp'
require_relative 'lib'
$LOAD_PATH.unshift './ksp/lib/'
require 'ksp'
require_relative 'beaotic/beaotic'
debug = false

project_name = ARGV[0]
conf_file = "#{File.dirname(__FILE__)}/#{project_name}"
@conf = parse_config(yaml_file(conf_file))

pp @conf if debug

key_groups = []
# Populate ruby elements
@conf[:key_groups].each do |key_group_conf|
  key_groups << Beaotic::KeyGroup.new(key_group_conf)
  puts "{ Key group: #{key_groups.last.name} } \n"
end

# TODO Refactor into an on_init method
puts 'on init'
puts '  ' + 'make_perfview'
puts '  ' + "set_script_title(\"#{project_name}\")"
puts '  ' + "set_ui_height_px(#{@conf[:perf_view][:height_px]})"
puts '  ' + 'declare $viewmode := 0'
# puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "_reference_group")'
puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")'
puts '  ' + 'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "icon_hejo")'

# puts '
# declare ui_switch $title_bd
# set_control_par_str(get_ui_id($title_bd),$CONTROL_PAR_TEXT,"")
# set_control_par_str(get_ui_id($title_bd),$CONTROL_PAR_PICTURE,"title_bd")
# set_control_par(get_ui_id($title_bd),$CONTROL_PAR_HEIGHT,16)
# set_control_par(get_ui_id($title_bd),$CONTROL_PAR_WIDTH,468)
# move_control_px($title_bd,83,0)
# '

# puts '  ' + "declare %panels[#{key_groups.count}*2]"

key_groups.each do |key_group|
  key_group.title_image.declare.each do |statememt|
    puts '  '  + statememt
  end

  puts '  ' + key_group.title_image.set_position(83, 0)

  x = 21
  y = 84

  key_group.knobs.each do |knob|
    knob.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + knob.set_position(x, y)
    x += 78
    # define image properties
    # define placement
    puts ''
  end
  # puts '  ' + key_group.main_panel
  puts ''
end


puts 'end on'

# declare user defined functions
key_groups.each do |key_group|
  # puts key_group.functions
  # key_group.knobs.each do |knob|
  #   puts knob.function
  # end
end

# declare ui callbacks
key_groups.each do |key_group|
  key_group.knobs.each do |knob|
    # puts knob.callback
  end
end

# declare midi callbacks




