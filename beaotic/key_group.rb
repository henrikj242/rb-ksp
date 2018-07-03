module Beaotic
  class KeyGroup
    attr :conf, :knobs, :edit_buttons, :edit_button_dividers, :mix_panel,
         :title_image, :diode, :backdrops, :keys, :round_robin_entries,
         :main_panel_elements

    def initialize(key_group_conf)
      @gui_directory = '_gui'
      @conf = key_group_conf


      @conf[:knobs].each_index do |index|
        if @conf[:knobs][index][:affected_keys].nil?
          @conf[:knobs][index][:affected_keys] = 0..@conf[:keys].count-1
        end
      end
      # @functions = []
      @knobs = []
      @edit_buttons = []
      @edit_button_dividers = []
      @main_panel_name = "%panel_main_#{name}"
      @main_panel_elements = []
      @keys = []
      set_title_image
      # set_functions
      set_diode
      set_knobs
      set_edit_buttons

      # set_main_panel
      set_mix_panel
      set_keys
    end

    def name
      @conf[:name]
    end

    def set_title_image
      @title_image = Ksp::UiImage.new("title_#{name}", image: "title_#{name}")
    end

    def set_diode
      @diode = Ksp::CustomDiode.new(name, levels: 3)
    end

    def main_panel
      @main_panel_elements = @knobs.map(&:name) +
          @knobs.map{ |knob| knob.label.name if knob.label } +
          @edit_buttons.map(&:name) +
          @edit_button_dividers.map(&:name)
      @main_panel_elements << @title_image.name
      statements = ["declare #{@main_panel_name}[#{@main_panel_elements.count}]"]
      @main_panel_elements.each_with_index { |elem, idx | statements << "#{@main_panel_name}[#{idx}] := get_ui_id(#{elem})" }
      statements
    end

    def main_panel_hide
      statements = ["function hide_panel_main_#{name}"]
      @main_panel_elements.each do |elem|
        statements << "  hide_part(#{elem}, $HIDE_WHOLE_CONTROL)"
      end
      statements << "end function"
    end

    def main_panel_show
      statements = ["function show_panel_main_#{name}"]
      @main_panel_elements.each do |elem|
        statements << "  hide_part(#{elem}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      end
      statements << "end function"
    end

    def set_mix_panel
      @mix_panel = MixPanel.new
    end

    def functions
      default_functions + feature_functions
    end

    def set_knobs
      @conf[:knobs].each do |knob_conf|
        knob_identifier = "#{name}_#{knob_conf[:name]}"
        @knobs << Ksp::CustomKnob.new(knob_identifier, knob_conf.merge(key_group_name: name))
        knob_conf[:affected_keys].each do |ak|
          label = "label_#{knob_conf[:name]}"
          @knobs.last.label = Ksp::UiImage.new("label_#{knob_identifier}", image: label)
          @knobs.last.k_groups[:osc1] += @conf[:keys][ak][:k_groups][:osc1]
          if @conf[:keys][ak][:k_groups][:osc2]
            @knobs.last.k_groups[:osc2] += @conf[:keys][ak][:k_groups][:osc2]
          end
        end
        # @knobs.last.set_callback()
      end
    end

    def set_edit_buttons
      @conf[:edit_buttons].each do |k, v|
        button_identifier = "#{name}_#{k}"
        v = v.merge(image: "button_#{k}", key_group_name: name)
        @edit_buttons << Ksp::CustomButton.new(button_identifier, v)

        v = v.merge(image: "img_edit_button_divider", add_to_height: 1)
        divider_identifier = "#{name}_#{k}"
        @edit_button_dividers << Ksp::UiImage.new(divider_identifier, v)
      end
    end

    def default_functions
      pitch_functions + default_edit_button(:osc_drift) +  default_edit_button(:vel_start) + default_edit_button(:vel_vca)
      # volume_functions
      # pan_functions
      # output_assign_functions
    end


    # def volume_functions
    #   statements = ["{ default volume functions }"]
    #   @conf[:keys].each do |affected_key|
    #     mix_volume_function(affected_key).map do |statement|
    #       statements << statement
    #     end
    #   end
    #
    #   statements << "function set_volume_#{@conf[:name]}"
    #   @conf[:keys].each do |affected_key|
    #     statements << "  call set_volume_#{@conf[:name]}_#{affected_key[:name]} "
    #   end
    #   statements << "end function"
    #   statements
    # end
    #
    # def mix_volume_function(affected_key)
    #   main_knob = "$knob_#{@conf[:name]}_volume"
    #   mix_knob = "$knob_#{@conf[:name]}_#{affected_key[:name]}_volume"
    #   statements = []
    #   statements << "function #{@conf[:name]}_#{affected_key[:name]}_volume"
    #   affected_key[:k_groups].keys.each do |osc|
    #     affected_key[:k_groups][osc].each do |k_group|
    #       statements << "  set_engine_par($ENGINE_PAR_VOLUME, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
    #     end
    #   end
    #   statements << "end function"
    #   statements
    # end

    def mix_pitch_function(affected_key)
      main_knob = "$knob_#{@conf[:name]}_pitch"
      # mix_knob = "$knob_#{@conf[:name]}_#{affected_key[:name]}_pitch"
      mix_knob = "500000"
      statements = []
      statements << "function #{@conf[:name]}_#{affected_key[:name]}_pitch"

      # we always pitch osc1
      affected_key[:k_groups][:osc1].each do |k_group|
        statements << "  set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
      end
      # we only pitch osc 2 if feature is enabled and button is pressed
      if @conf.fetch(:features, {}).fetch(:pitch_osc2, {}) != {}
        activator = edit_buttons.select{ |button| button.identifier == @conf[:features][:pitch_osc2] }.first
        statements << "  if (#{activator.name} = 1)"
        affected_key[:k_groups][:osc2].each do |k_group|
          statements << "    set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
        end
        statements << '  end if'
      end
      statements << "end function"
    end

    def pitch_functions
      statements = ["{ default pitch functions }\n"]
      @conf[:keys].each do |affected_key|
        mix_pitch_function(affected_key).each do |statement|
          statements << statement
        end
      end
      statements << "function #{@conf[:name]}_pitch"
      @conf[:keys].each do |affected_key|
        statements << "  call #{@conf[:name]}_#{affected_key[:name]}_pitch"
      end
      statements << "end function \n"
    end

    def k_groups
      k_groups = []
      @conf[:keys].each { |key| key[:k_groups].each_pair{ |_, k_grps| k_grps.map { |k_group| k_groups << k_group } } }
      k_groups
    end

    def default_edit_button(button_name)
      button = edit_buttons.select{ |edit_button| edit_button.identifier == "#{@conf[:name]}_#{button_name}" }.first
      statements = []
      statements << "function #{@conf[:name]}_#{button_name}"
      k_groups.each do |k_group|
        statements << "  if (#{button.name} = 1)"
        statements << "    set_engine_par($ENGINE_PAR_MOD_TARGET_INTENSITY, " \
          "#{@conf[:edit_buttons][button_name][:intensity]}, #{k_group}, "\
          "find_mod(#{k_group}, \"#{@conf[:edit_buttons][button_name][:modulator]}\"), -1)"
        statements << "  else "
        statements << "    set_engine_par($ENGINE_PAR_MOD_TARGET_INTENSITY, 0, #{k_group}, find_mod(#{k_group}, "\
          " \"#{@conf[:edit_buttons][button_name][:modulator]}\"), -1)"
        statements << '  end if'
      end
      statements << 'end function'
    end

    def pitch_osc2_function
      main_knob = "$knob_#{@conf[:name]}_pitch"
      mix_knob = 500000
      statements = ["function #{name}_pitch_osc2"]
      activator = edit_buttons.select{ |button| button.identifier == @conf[:features][:pitch_osc2] }.first
      statements << "  if (#{activator.name} = 1)"
      @conf[:keys].each do |key|
        key[:k_groups][:osc2].each do |k_group|
          statements << "    set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
        end
      end
      statements << '  else'
      @conf[:keys].each do |key|
        key[:k_groups][:osc2].each do |k_group|
          statements << "    set_engine_par($ENGINE_PAR_TUNE, 500000, #{k_group}, -1, -1)"
        end
      end
      statements << '  end if'
      statements << 'end function'
    end

    def feature_functions
      statements = []
      if @conf[:features].include?(:link_decays)
        link_decays_functions.map{ |statement| statements << statement }
      end
      if @conf[:features].include?(:pitch_osc2)
        pitch_osc2_function.map{ |statement| statements << statement }
      end
      statements
    end

    def link_decays_functions
      button_identifer = "#{name}_#{@conf[:features][:link_decays][:button]}"
      link_decays_button = edit_buttons.select{ |button| button.identifier == button_identifer }.first
      knob_identifiers = @conf[:features][:link_decays][:knobs].map{ |knob| "#{name}_#{knob}" }
      link_decay_knobs = knobs.select{ |knob| knob_identifiers.include?(knob.identifier) }
      statements = []
      # statements << "{ #{link_decay_knobs.inspect} }"
      statements << "function #{name}_link_decays_1"
      statements << "  if (#{link_decays_button.name} = 1)"
      link_decay_knobs[1..-1].map{ |knob| statements << "    #{knob.name} := #{link_decay_knobs[0].name}" }
      statements << "  end if"
      statements << "end function"
      statements << "function #{name}_link_decays_2"
      statements << "  if (#{link_decays_button.name} = 1)"
      statements << "    #{link_decay_knobs[0].name} := #{link_decay_knobs[1].name}"
      statements << "  end if"
      statements << "end function"
      statements
    end

    def set_keys
      extra_options = {
          key_group_name: name
      }
      extra_options[:features] = @conf[:features] if @conf[:features]

      @conf[:keys].each_with_index do |key, idx|
        @keys << Beaotic::Key.new(self, idx, key.merge(extra_options))
        @keys.last.set_callback
        @keys.last.set_off_callback
      end
    end

    def print
      puts '  ' + "declare $#{name}_round_robin_next := 1"
      puts '  ' + "declare $#{name}_round_robin_max := #{conf[:features][:round_robin][:entries]}"
      puts '  ' + "declare $#{name}_new_event"
      puts '  ' + "declare $#{name}_new_velocity"
      puts '  ' + "declare @#{name}_message"

      keys.each do |key|
        key.set_k_groups.each do |statement|
          puts '  ' + statement
        end
      end

      title_image.declare.each do |statememt|
        puts '  '  + statememt
      end
      puts '  ' + title_image.set_position(82, 0)

      # diode.declare.each do |statememt|
      #   puts '  '  + statememt
      # end
      # puts '  ' + diode.set_position(93 + key_group_index * 36, 249)

      y = 84
      knobs.each_with_index do |knob, knob_index|
        knob.declare.each do |statement|
          puts '  ' + statement
        end
        x = knob.conf[:position] ?
                19 + (knob.conf[:position][0] * 78) :
                19 + (knob_index * 78)
        puts '  ' + knob.set_position(x, y)
        knob.label.declare.each do |statement|
          puts '  ' + statement
        end
        puts '  ' + knob.label.set_position(x-16, y - 41)
        puts ''
      end

      x = 18
      y = 179
      edit_buttons.each do |button|
        button.declare.each do |statement|
          puts '  ' + statement
        end
        puts '  ' + button.set_position(x, y)
        x += 51
      end

      x = 65
      y = 179
      edit_button_dividers.each do |divider|
        divider.declare.each do |statement|
          puts '  ' + statement
        end
        puts '  ' + divider.set_position(x, y)
        x += 51
      end

      # puts '{ Global buttons // group_select }'
      # button = group_select_buttons[key_group_index]
      # button.declare.each do |statement|
      #   puts '  ' + statement
      # end
      # puts '  ' + button.set_position(83 + key_group_index * 36, 226)

      main_panel.each do |statement|
        puts '  ' + statement
      end
      puts ''
    end
  end
end