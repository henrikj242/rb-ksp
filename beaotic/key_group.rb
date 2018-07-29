module Beaotic
  class KeyGroup
    attr_reader :conf
    attr :knobs, :edit_buttons, :edit_button_dividers, :mix_panel,
         :title_image, :diode, :backdrops, :keys, :round_robin_entries,
         :main_panel_elements, :main_panel

    def initialize(conf)
      @conf = conf
      @functions = []
      @keys = []
    end

    def name
      @conf[:name]
    end

    def set_diode
      @diode = Beaotic::Diode.new(name: "#{name}", levels: 3)
    end

    def set_main_panel
      @main_panel = MainPanel.new(@conf)
      @main_panel.set_knobs
      @main_panel.set_edit_buttons
      @main_panel.set_main_panel_elements
      @main_panel.set_functions
    end

    def set_mix_panel
      @mix_panel = MixPanel.new(@conf)
      @mix_panel.set_functions
    end

    def functions
      pitch_functions_mix
      pitch_function_main
      @functions
    end

    def ui_callbacks
      @mix_panel.channels.map do |ch|
        ch.pitch_knob.callbacks
      end.flatten
    end

      # def set_callbacks
      #   @main_panel.knobs.each do |knob|
      #     knob.add_callbacks(ui_control_callbacks(knob, knob_conf))
      #   end
      # end

    def functions_obsolete
      default_functions + feature_functions
    end

    def default_functions_obsolete
      pitch_functions +
          default_edit_button(:osc_drift) +
          default_edit_button(:vel_start) +
          default_edit_button(:vel_vca)
    end

    def pitch_functions_mix
      statements = []
      @mix_panel.channels.each_with_index do |ch, idx|
        @conf[:keys][idx][:k_groups].each do |osc, k_groups|
          statements << "if (#{ch.pitch_mode_button.name} = 0) "
          k_groups.each do |k_group|
            statements << "  set_engine_par($ENGINE_PAR_TUNE, $knob_#{name}_pitch + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
            statements << "message (\" & $knob_#{name}_pitch + #{ch.pitch_knob.name} &  \")"
          end
          statements << "else "
          k_groups.each do |k_group|
            statements << "  set_engine_par($ENGINE_PAR_TUNE, 500000 + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
          end
          statements << "end if"
        end
        @functions << Ksp::Function.new("#{name}_#{@conf[:keys][idx][:name]}_pitch").set_body(statements)
      end
    end

    def pitch_function_main
      body = @conf[:keys].map{|key| "call #{name}_#{key[:name]}_pitch" }
      @functions << Ksp::Function.new("#{name}_pitch").set_body(body)
    end

    def mix_pitch_function_obsolete(affected_key)
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
        activator = main_panel.edit_buttons.select{ |button| button.identifier == @conf[:features][:pitch_osc2] }.first
        statements << "  if (#{activator.name} = 1)"
        affected_key[:k_groups][:osc2].each do |k_group|
          statements << "    set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
        end
        statements << '  end if'
      end
      statements << "end function"
    end

    def pitch_functions_obsolete
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

    def k_groups_obsolete
      k_groups = []
      @conf[:keys].each { |key| key[:k_groups].each_pair{ |_, k_grps| k_grps.map { |k_group| k_groups << k_group } } }
      k_groups
    end

    def default_edit_button_obsolete(button_name)
      button = main_panel.edit_buttons.select{ |edit_button| edit_button.identifier == "#{@conf[:name]}_#{button_name}" }.first
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

    def pitch_osc2_function_obsolete
      main_knob = "$knob_#{@conf[:name]}_pitch"
      mix_knob = 500000
      statements = ["function #{name}_pitch_osc2"]
      activator = main_panel.edit_buttons.select{ |button| button.identifier == @conf[:features][:pitch_osc2] }.first
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

    def link_decays_functions_obsolete
      button_identifer = "#{name}_#{@conf[:features][:link_decays][:button]}"
      link_decays_button = main_panel.edit_buttons.select{ |button| button.identifier == button_identifer }.first
      knob_identifiers = @conf[:features][:link_decays][:knobs].map{ |knob| "#{name}_#{knob}" }
      link_decay_knobs = main_panel.knobs.select{ |knob| knob_identifiers.include?(knob.identifier) }
      statements = []
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
      @conf[:keys].each do |key_conf|
        @keys << Beaotic::Key.new(key_conf)
        # @callbacks[key_conf[:name]]
      end

      # extra_options = {
      #     key_group_name: name
      # }
      # extra_options[:features] = @conf[:features] if @conf[:features]
      #
      # @conf[:keys].each_with_index do |key, idx|
      #   @keys << Beaotic::Key.new(self, idx, key.merge(extra_options))
      #   @keys.last.set_callback
      #   @keys.last.set_off_callback
      # end
    end

    def callback_key_round_robin
      statements = []
      if @conf.fetch(:features, {}).fetch(:round_robin, {}) != {}
        statements = [
            "$#{name}_round_robin_next := ($#{name}_round_robin_next+1) mod $#{name}_round_robin_max"
        ]
      end
      statements
    end

    def osc2_color_conf
      @conf[:knobs].select{ |k| k[:name] == @conf[:features][:osc2_color] }.first
    end

    def split_count(split_target)
      splits = case split_target
               when :color
                 osc2_color_conf[:max_val]
               when :round_robin
                 @conf[:features][:round_robin][:entries]
               end

      (splits.to_i * 2).to_s unless @conf[:features][:accent][:velocity_threshold].nil?
    end

    def disallow_all(key)
      statements = []
      key[:k_groups].each do |k, osc|
        osc.each do |k_group_id|
          statements << "disallow_group(#{k_group_id})"
        end
      end
      statements
    end

    def allow(midi_note, osc_key, osc)
      statements = ["{allowing ... }"]
      case @conf[:features][:velocity_to][osc_key]
      when 'round_robin'
        osc.each do |k_group_id|
          statements << "allow_group(#{k_group_id})"
        end
      when 'osc2_color'
        statements << "allow_group(%key_#{midi_note}_k_groups_osc2[$#{name}_round_robin_next])"
      end
      statements
    end

    def dest_velocity(osc)
      case @conf[:features][:velocity_to][osc]
      when 'round_robin'
        [
          "if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})",
          "  $#{name}_new_velocity := %velocity_splits_#{split_count(:round_robin)}[$#{name}_round_robin_next]",
          "else",
          "  $#{name}_new_velocity := %velocity_splits_#{split_count(:round_robin)}[$#{name}_round_robin_next + #{@conf[:features][:round_robin][:entries]}]",
          "end if",
        ]
      when 'osc2_color'
        [
          "if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})",
          "  $#{name}_new_velocity := %velocity_splits_#{split_count(:color)}[$knob_#{name}_#{osc2_color_conf[:name]} - 1]",
          "else",
          "  $#{name}_new_velocity := %velocity_splits_#{split_count(:color)}[$knob_#{name}_#{osc2_color_conf[:name]}  - 1 + #{osc2_color_conf[:max_val]}]",
          "end if"
        ]
      end
    end

    def play_new_velocity
      [
        "$#{name}_new_event := play_note($EVENT_NOTE, $#{name}_new_velocity, 0, -1)"
      ]
    end

    def callback_key_diode(key_conf)
      [
        "if ($EVENT_VELOCITY >= #{@conf[:features][:accent][:velocity_threshold]})",
        "  $diode_#{name}_#{key_conf[:name]} := 2",
        "else",
        "  $diode_#{name}_#{key_conf[:name]} := 1",
        "end if"
      ]
    end

    # def set_decay
    #   statements = []
    #   # find knobs with callback: 'decay' and affected_keys including me based on my midi_note and idx
    #   knobs = @key_group.main_panel.knobs.select{ |k| k.conf[:callback] == 'decay' && k.conf[:affected_keys].include?(@idx) }
    #   knobs.each do |knob|
    #     knob.conf[:affected_oscs].each do |affected_osc|
    #       @conf[:k_groups][affected_osc.to_sym].each do |k_group|
    #         statements << "set_engine_par(#{knob.conf[:parameter]}, #{knob.name}, #{k_group}, find_mod(#{k_group}, \"#{knob.conf[:modulator]}\"), -1)"
    #       end
    #     end
    #   end
    #   statements
    # end

    def on_note_callbacks
      statements = []
      # Listen for individual notes in the key_group
      @conf[:keys].map do |key|
        statements << [
          "if ($EVENT_NOTE = #{key[:midi_note]})",
            callback_key_diode(key).map{ |stm| '  ' + stm },
            callback_key_round_robin.map{ |stm| '  ' + stm },
            disallow_all(key).map{ |stm| '  ' + stm },
            key[:k_groups].map do |k, osc|
              dest_velocity(k).map { |stm| '  ' + stm } +
                allow(key[:midi_note], k, osc).map { |stm| '  ' + stm } +
                play_new_velocity.map { |stm| '  ' + stm }
            end,
          "end if"
        ].join("\n  ")
      end

      # Listen for notes belonging to the key_group
      statements += [
        "if (search(%#{name}_midi_notes, $EVENT_NOTE) # -1)"
      ]

      # Note callbacks based on key_group knobs
      @main_panel.knobs.each do |knob|
        statements += [
          "  "
        ]
      end

      # Activate the key_group diode
      statements += [
        "  if ($EVENT_VELOCITY >= #{@conf[:features][:accent][:velocity_threshold]})",
        "    #{@diode.name} := 2",
        "  else",
        "    #{@diode.name} := 1",
        "  end if"
      ]

      # Select the key_group if Midi Select is enabled
      statements += [
        "  if ($button_#{@conf[:features][:midi_select][:group_selector]} = 1)",
        "    $selected_group := #{@conf[:index]}",
        "    call #{@conf[:features][:midi_select][:function].gsub('KEY_GROUP', name)}",
        "  end if"
      ]

      # Trash the original note event
      statements += [
        "  change_note($EVENT_ID, 0)",
        "end if"
      ]
    end

    def on_release_callbacks
      @conf[:keys].map do |key|
        [
          "if ($EVENT_NOTE = #{key[:midi_note]})",
          "  $diode_#{name}_#{key[:name]} := 0",
          "end if"
      ].join("\n")
      end +
      [
        "if (search(%#{name}_midi_notes, $EVENT_NOTE) # -1)",
        "  #{@diode.name} := 0",
        "end if"
    ]
    end

    def statements
      statements = [
        "declare $#{name}_round_robin_next := 1",
        "declare $#{name}_round_robin_max := #{conf[:features][:round_robin][:entries]}",
        "declare $#{name}_new_event",
        "declare $#{name}_new_velocity",
        "declare @#{name}_message"
      ]

      statements += Ksp::Variable.new(
        type: 'integer_array',
        name: "#{name}_midi_notes",
        arr_length: @keys.count,
        default_value: @keys.map(&:midi_note)
      ).statements

      @keys.each do |key|
        key.set_k_groups.each do |statement|
          statements << statement
        end
      end
      statements += main_panel.title_image.statements
      statements += @diode.statements

      main_panel.knobs.each do |knob|
        statements += knob.statements
      end

      main_panel.edit_buttons.each do |button|
        statements += button.statements
      end

      main_panel.edit_button_dividers.each do |divider|
        statements += divider.statements
      end

      mix_panel.channels.each do |channel|
        channel.elements.each do |element|
          statements += element.statements
        end
      end

      statements.map { |statement| '  ' + statement }
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


  end
end