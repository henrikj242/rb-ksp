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
key_group_indexes = {}
# Populate ruby elements
@conf[:key_groups].each_with_index do |key_group_conf, idx|
  key_groups << Beaotic::KeyGroup.new(key_group_conf)
  group_select_buttons << Ksp::CustomButton.new(
    "group_#{key_group_conf[:name]}",
    name: "group_#{key_group_conf[:name]}",
    image: "button_group_#{key_group_conf[:name]}",
    function: "select_group_#{key_group_conf[:name]}"
  )
  key_group_indexes[key_group_conf[:name]] = idx
end

# TODO Refactor into an on_init method
puts 'on init'
puts '  ' + 'message("")'
puts '  ' + 'make_perfview'
puts '  ' + "set_script_title(\"#{project_name}\")"
puts '  ' + "set_ui_height_px(#{@conf[:perf_view][:height_px]})"
# puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "_reference_group")'
puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")'
puts '  ' + 'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "icon_hejo")'
puts '  ' + 'declare $selected_group := 0'

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

  key_group.main_panel_declare.each do |statement|
    puts '  ' + statement
  end
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
button_note_edit = Ksp::CustomButton.new('note_edit', name: 'note_edit', image: 'button_note_edit', function: 'set_display')
button_note_edit.declare.each do |statement|
  puts '  ' + statement
end
puts '  ' + button_note_edit.set_position(546, 222)
puts '  ' + '$button_note_edit := 0'
puts 'end on'

key_groups.each do |key_group|
  key_group.main_panel_hide.each do |statement|
    puts statement
  end
  key_group.main_panel_show.each do |statement|
    puts statement
  end
end

# declare global functions
puts 'function set_display'
key_groups.each do |key_group|
  puts '  ' + "call hide_panel_main_#{key_group.name}"
end
puts '  ' + 'if ($button_note_edit = 0)'
puts '  ' + '  select ($selected_group)'
key_groups.each_with_index do |key_group, key_group_idx|
  puts '  ' + "    case #{key_group_idx}"
  puts '  ' + "      message(\"selecting #{key_group.name}\")"
  puts '  ' + "      call show_panel_main_#{key_group.name}"
end
puts '  ' + '  end select'
puts '  ' + 'end if'
puts 'end function'

# declare global functions per key_group
global_key_group_functions = []
key_groups.each do |key_group_me|
  global_key_group_functions << []
  global_key_group_functions.last << "function select_group_#{key_group_me.name}"
  key_groups.each do |key_group_other|
    val = key_group_other.name ==  key_group_me.name ? '1' : '0'
    global_key_group_functions.last << "  $button_group_#{key_group_other.name} := #{val}"
  end
  global_key_group_functions.last <<  '  call set_display'
  global_key_group_functions.last << 'end function'
end
global_key_group_functions.each do |global_key_group_function|
  global_key_group_function.each do |statement|
    puts statement
  end
end


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
  key_group.edit_buttons.each do |knob|
    # puts knob.callback
  end
  puts "on ui_control ($button_group_#{key_group.name})"
  puts "  $selected_group := #{key_group_indexes[key_group.name]}"
  puts "  call select_group_#{key_group.name}"
  puts 'end on'
end

# declare global callbacks
puts 'on ui_control($button_note_edit)'
puts '  ' + 'call set_display'
puts 'end on'

# declare midi callbacks




