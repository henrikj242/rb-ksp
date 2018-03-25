#! /usr/bin/ruby

require 'erb'
require 'yaml'
require 'pp'
require_relative 'lib'
$LOAD_PATH.unshift './ksp/lib/'
require 'ksp'
require_relative 'beaotic/beaotic'
debug = false

project_name = ARGV[0]
conf_file = yaml_file("#{File.dirname(__FILE__)}/#{project_name}")
@conf = parse_config(conf_file)

pp @conf if debug

if ARGV[1] == 'img-txt'
  img = Beaotic::Image.new
  img.generate_txt_files
  exit(0)
end

key_groups = []
group_select_buttons = []
# Populate ruby elements
@conf[:key_groups].each do |key_group_conf|
  key_groups << Beaotic::KeyGroup.new(key_group_conf)
  group_select_buttons << Ksp::CustomButton.new("group_#{key_group_conf[:name]}", name: "group_#{key_group_conf[:name]}", image: "button_group_#{key_group_conf[:name]}")
end

# TODO Refactor into an on_init method
puts 'on init'
puts '  ' + 'message("")'
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

  # y = 200
  # key_group.backdrops.each do |backdrop|
  #   backdrop.declare.each do |statement|
  #     puts '  ' + statement
  #   end
  #   puts '  ' + backdrop.set_position(10, y)
  #   y += 100
  # end

  x = 21
  y = 84

  key_group.knobs.each do |knob|
    knob.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + knob.set_position(x, y)
    knob.label.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + knob.label.set_position(x-18, y - 41)
    x += 78
    puts ''
  end

  x = 17
  y = 179
  key_group.edit_buttons.each do |button|
    button.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + button.set_position(x, y)
    x += 51
  end

  # puts '  ' + key_group.main_panel
  puts ''
end

puts '{ Global buttons // midi_select }'
button_midi_select = Ksp::CustomButton.new('midi_select', name: 'midi_select', image: 'button_midi_select')
button_midi_select.declare.each do |statement|
  puts '  ' + statement
end
puts '  ' + button_midi_select.set_position(7, 222)

puts '{ Global buttons // group_select }'
x = 83
group_select_buttons.each do |button|
  button.declare.each do |statement|
    puts '  ' + statement
  end
  puts '  ' + button.set_position(x, 226)
  x += 36
end


puts '{ Global buttons // note_edit }'
button_note_edit = Ksp::CustomButton.new('note_edit', name: 'note_edit', image: 'button_note_edit')
button_note_edit.declare.each do |statement|
  puts '  ' + statement
end
puts '  ' + button_note_edit.set_position(546, 222)


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




