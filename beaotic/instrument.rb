module Beaotic
  class Instrument
    def initialize(project_name)
      @conf = parse_config("./#{project_name}.yml")
      @debug_file = File.new("./#{project_name}.debug", 'w')
      @key_groups = []
      populate_key_groups
      define_script
    end

    def define_script
      @script = Ksp::Script.new
      @script.on_init = on_init
      @key_groups.each do |key_group|
        @script.functions += key_group.main_panel.functions.flatten
        @script.functions += key_group.mix_panel.functions.flatten
      end

      @script.functions += global_functions
      @script.on_ui_control_callbacks = on_ui_control_callbacks
      @script.on_note_callback = on_note_callback
      @script.on_release_callback = on_release_callback
    end

    def on_note_callback
      @key_groups.map(&:diode_on_callbacks).flatten
    end

    def on_release_callback
      @key_groups.map(&:diode_off_callbacks).flatten
    end

    def on_ui_control_callbacks
      global_buttons.map { |b| b.callback }
    end

    def populate_key_groups
      @conf[:key_groups].each_with_index do |key_group_conf, idx|
        key_group_conf = key_group_conf.merge(index: idx)
        key_group = Beaotic::KeyGroup.new(key_group_conf)
        key_group.set_main_panel
        key_group.set_diode
        key_group.diode.xy(95 + (idx * 36), 250)
        key_group.set_mix_panel
        key_group.set_keys
        @key_groups << key_group
      end
    end

    def global_functions
      [func_set_display] +
      @key_groups.map do |key_group_to_choose|
        f = Ksp::Function.new("select_group_#{key_group_to_choose.name}")
        f.append(
            @key_groups.map do |key_group_any|
              "$button_group_#{key_group_any.name} := #{key_group_any.name == key_group_to_choose.name ? 1 : 0}"
            end
        )
        f.append(["call set_display"])
      end
    end

    def global_buttons
      button_midi_select = Ksp::UiSwitch.new(
        name: 'button_midi_select',
        default_value: 1,
        picture: 'button_midi_select',
        persistent: false
      )
      button_midi_select.xy(1, 224)
      button_note_edit = Ksp::UiSwitch.new(
        name: 'button_note_edit',
        default_value: 0,
        picture: 'button_note_edit',
        persistent: false
      )
      button_note_edit.xy(550, 224)
      button_note_edit.callback.body = [
        'call set_display'
      ]
      buttons = [button_midi_select, button_note_edit]
      @key_groups.each_with_index do |key_group, idx|
        b = Ksp::UiSwitch.new(
          name: "button_group_#{key_group.name}",
          default_value: key_group.name == 'bd' ? 1 : 0,
          picture: "button_group_#{key_group.name}"
        )
        b.xy(83 + (idx * 36), 226)
        b.callback.body = [
          "$selected_group := #{idx}",
          "call select_group_#{key_group.name}"
        ]
        buttons << b
      end
      buttons
    end

    def on_init
      statements = [
        "message(\"Built by Ksp::Beaotic at #{Time.now}\")",
        'make_perfview',
        "set_script_title(\"#{@conf[:global][:project_name]}\")",
        "set_ui_height_px(#{@conf[:global][:perf_view][:height_px]})",
        'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")',
        'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "img_icon_hejo")',
        'declare $selected_group := 0',
      ].map { |line|  '  ' + line }
      statements += global_buttons.map do |button|
        button.statements.map { |line|  '  ' + line }
      end
      statements += @key_groups.map(&:statements)


      # Hide everything except the BD Main Panel
      @key_groups.each do |kg|
        if kg.name != 'bd'
          kg.main_panel.elements.each do |elem|
            statements << "  hide_part(#{elem}, $HIDE_WHOLE_CONTROL)"
          end
        else
          ''
        end
        kg.mix_panel.channels.each do |channel|
          channel.elements.each do |elem|
            statements << "  hide_part(#{elem.name}, $HIDE_WHOLE_CONTROL)"
          end
        end
      end
      statements
    end

    def func_set_display
      set_display = Ksp::Function.new('set_display')
      @key_groups.each do |key_group|
        set_display.append [
          "  call hide_panel_main_#{key_group.name}",
          "  call hide_panel_mix_#{key_group.name}"
        ]
      end
      set_display.append ['  select ($selected_group)']
      @key_groups.each_with_index do |key_group, key_group_idx|
        set_display.append [
          "    case #{key_group_idx}",
          "      message(\"selecting #{key_group.name}\")",
          '      if ($button_note_edit = 0)',
          "        call show_panel_main_#{key_group.name}",
          '      else',
          "        call show_panel_mix_#{key_group.name}",
          '      end if'
        ]
      end
      set_display.append ['  end select']
    end

    def print
      statements.each { |statement| puts statement }
    end

    def statements
      @script.statements
    end

    def var_dump
      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp @conf, @debug_file

      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp @key_groups, @debug_file

      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp statements, @debug_file
    end

    # symbolize function Grapped from https://gist.github.com/Integralist/9503099
    # modified by myself to support Ranges
    def symbolize(obj)
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

    def parse_config(conf_file)
      symbolize(YAML::load_file(conf_file))
    end
  end
end