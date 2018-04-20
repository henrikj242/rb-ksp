#! /usr/bin/ruby

require 'time'
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
  img = Beaotic::Image.new(@conf[:perf_view])
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
    function: "select_group_#{key_group_conf[:name]}",
    options: [:no_persist, :no_auto]
  )
  key_group_indexes[key_group_conf[:name]] = idx
end


puts "{ Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
# ==========   ON INIT
# TODO Refactor into an on_init method
puts 'on init'
puts '  ' + 'message("")'
puts '  ' + 'make_perfview'
puts '  ' + "set_script_title(\"#{project_name}\")"
puts '  ' + "set_ui_height_px(#{@conf[:perf_view][:height_px]})"
# puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "_reference_group")'
puts '  ' + 'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")'
puts '  ' + 'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "icon_hejo")'

puts '  ' + "declare ui_knob $accent(1, #{@conf[:accent][:volume_boost_max].to_i * 1000}, 1)"

Ksp::Utility.split_lists_declare.each do |statement|
  puts '  ' + statement
end

puts '  ' + 'declare $selected_group := 0'

key_groups.each_with_index do |key_group, index|
  puts '  ' + "declare $#{key_group.name}_round_robin_next := 1"
  puts '  ' + "declare $#{key_group.name}_round_robin_max := #{key_group.conf[:features][:round_robin][:entries]}"
  puts '  ' + "declare $#{key_group.name}_new_velocity"

  key_group.keys.each do |key|
    key.set_k_groups.each do |statement|
      puts '  ' + statement
    end
  end

  key_group.title_image.declare.each do |statememt|
    puts '  '  + statememt
  end
  puts '  ' + key_group.title_image.set_position(82, 0)

  key_group.diode.declare.each do |statememt|
    puts '  '  + statememt
  end
  puts '  ' + key_group.diode.set_position(93 + index * 36, 249)

  x = 19
  y = 84
  key_group.knobs.each do |knob|
    knob.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + knob.set_position(x, y)
    knob.label.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + knob.label.set_position(x-16, y - 41)
    x += 78
    puts ''
  end

  x = 18
  y = 179
  key_group.edit_buttons.each do |button|
    button.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + button.set_position(x, y)
    x += 51
  end

  x = 65
  y = 179
  key_group.edit_button_dividers.each do |divider|
    divider.declare.each do |statement|
      puts '  ' + statement
    end
    puts '  ' + divider.set_position(x, y)
    x += 51
  end

  puts '{ Global buttons // group_select }'
  button = group_select_buttons[index]
  button.declare.each do |statement|
    puts '  ' + statement
  end
  puts '  ' + button.set_position(83 + index * 36, 226)

  key_group.main_panel.each do |statement|
    puts '  ' + statement
  end
  puts ''
end

puts '{ Global buttons // midi_select }'
button_midi_select = Ksp::CustomButton.new(
    'midi_select',
    name: 'midi_select',
    image: 'button_midi_select',
    options: [:no_persist, :no_auto]
)
button_midi_select.declare.each do |statement|
  puts '  ' + statement
end
puts '  ' + button_midi_select.set_position(1, 224)
puts '  ' + button_midi_select.name + ' := 0'

puts '  $button_group_bd := 1'

puts '{ Global buttons // note_edit }'
button_note_edit = Ksp::CustomButton.new(
  'note_edit',
  name: 'note_edit',
  image: 'button_note_edit',
  function: 'set_display',
  options: [:no_persist, :no_auto]
)
button_note_edit.declare.each do |statement|
  puts '  ' + statement
end
puts '  ' + button_note_edit.set_position(550, 224)
puts '  ' + button_note_edit.name + ' := 0'

key_groups.select{ |kg| kg.name != 'bd' }.map{ |g| g.main_panel_elements.map{ |elem| puts "  hide_part(#{elem}, $HIDE_WHOLE_CONTROL)" } }

puts 'end on'
# =============== END ON INIT

# =============== GROUP SELECT
key_groups.each do |key_group|
  key_group.main_panel_hide.each do |statement|
    puts statement
  end
  key_group.main_panel_show.each do |statement|
    puts statement
  end
end

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

# =============== END GROUP SELECT


# declare user defined functions
key_groups.each do |key_group|
  key_group.functions.each do |statement|
    puts statement
  end
end

# declare knob functions - very short syntax
# key_groups.map{ |kg| kg.knobs.map{ |k| k.function.map{ |f| puts f } } }


# declare ui callbacks
key_groups.each do |key_group|
  key_group.knobs.each do |knob|
    puts knob.callback
  end
  key_group.edit_buttons.each do |button|
    puts button.callback
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
puts 'on note'
key_groups.each do |key_group|
  key_group.keys.each do |key|
    key.callback.each do |statement|
      puts '  ' + statement
    end
  end
end
puts 'end on'

puts 'on release'
key_groups.each do |key_group|
  key_group.keys.each do |key|
    key.off_callback.each do |statement|
      puts '  ' + statement
    end
  end
end
puts 'end on'
