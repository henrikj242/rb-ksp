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
        @script.functions += key_group.functions.flatten
      end

      @script.functions += global_functions
      @script.on_ui_control_callbacks = on_ui_control_callbacks
      @script.on_note_callback = on_note_callback
      @script.on_release_callback = on_release_callback
    end

    def on_note_callback
      @key_groups.map(&:on_note_callbacks).flatten
    end

    def on_release_callback
      @key_groups.map(&:on_release_callbacks).flatten
    end

    def on_ui_control_callbacks
      @key_groups.map{|key_group| key_group.main_panel.knobs.map(&:callbacks) }.flatten +
          @key_groups.map{|key_group| key_group.main_panel.edit_buttons.map(&:callbacks) }.flatten +
          @key_groups.map{|key_group| key_group.ui_callbacks}.flatten +
          global_buttons.map { |b| b.callbacks }
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
      button_note_edit.add_callbacks [
        'call set_display'
      ]
      buttons = [button_midi_select, button_note_edit]
      @key_groups.each_with_index do |key_group, idx|
        b = Ksp::UiSwitch.new(
          name: "button_group_#{key_group.name}",
          default_value: key_group.name == 'bd' ? 1 : 0,
          picture: "button_group_#{key_group.name}",
          persistent: false
        )
        b.xy(83 + (idx * 36), 226)
        b.add_callbacks [
          "$selected_group := #{idx}",
          "call select_group_#{key_group.name}"
        ]
        buttons << b
      end
      buttons
    end

    def logo
      l = Ksp::UiImage.new(name: 'logo', picture: 'img_logo')
      l.xy(5, 270)
      l.set_dimensions(add_to_height: 10)
      l
    end

    def accent_fader
      f = Beaotic::Fader.new(
          name: 'accent',
          direction: 'horizontal',
          label: 'accent',
          length: 50,
          min_val: @conf[:accent][:min_val],
          default_val: @conf[:accent][:default_val],
          max_val: @conf[:accent][:max_val],
          mouse_behaviour: @conf[:accent][:ui_control][:mouse_behaviour],
          visible: true
      )
      f.xy(555, 322)
      f.label_offset(0, -18)
      f
    end

    def on_init
      statements = [
        "message(\"Built by Ksp::Beaotic at #{Time.now}\")",
        "make_perfview",
        "set_script_title(\"#{@conf[:global][:project_name]}\")",
        "set_ui_height_px(#{@conf[:global][:perf_view][:height_px]})",
        "set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, \"wallpaper\")",
        "set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, \"img_icon_hejo\")",
        "declare $selected_group := 0",
        "declare $intensity := 0",
        "declare $i := 0",
        "declare $j := 0",
        "declare $volume := 0",
        "declare $pan := 0"
      ].map { |line|  '  ' + line }

      statements += Ksp::Variable.new(
          type:           'integer_array',
          name:           'velocity_db_mapping',
          default_value:  velocity_db_mapping
      ).statements
      statements += Ksp::Variable.new(
          type:           'integer_array',
          name:           'xfade_ksp_mapping',
          default_value:  xfade_ksp_mapping
      ).statements

      statements += Ksp::Utility.split_lists_declare.map{ |line| '  ' + line }

      statements += global_buttons.map do |button|
        button.statements.map { |line|  '  ' + line }
      end
      statements += accent_fader.statements
      statements += logo.statements
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
          # "      message(\"selecting #{key_group.name}\")",
          "      if ($button_note_edit = 0)",
          "        call show_panel_main_#{key_group.name}",
          "      else",
          "        call show_panel_mix_#{key_group.name}",
          "      end if"
        ]
      end
      set_display.append ['  end select']
    end

    def velocity_db_mapping
      db_range = -24000..3000
      vel_range = 0..127
      delta = db_range.count / vel_range.count
      vel_range.map{|velocity| db_range.first + velocity * delta }
    end

    def xfade_ksp_mapping
      (0..100).map do |x|
        (x ** (1.0/10) * 500).round
        # (Math.log(x+1) * 400).round
      end
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