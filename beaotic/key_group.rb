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

      # affect all keys/oscs if none specified
      @conf[:knobs].each_index do |index|
        if @conf[:knobs][index][:affected_keys].nil?
          @conf[:knobs][index][:affected_keys] = 0..@conf[:keys].count-1
        end
        if @conf[:knobs][index][:affected_oscs].nil?
          @conf[:knobs][index][:affected_oscs] = %w[osc1 osc2]
        end
      end

      @conf[:edit_buttons].keys.each do |key|
        if @conf[:edit_buttons][key][:affected_keys].nil?
          @conf[:edit_buttons][key][:affected_keys] = 0..@conf[:keys].count-1
        end
        if @conf[:edit_buttons][key][:affected_oscs].nil?
          @conf[:edit_buttons][key][:affected_oscs] = %w[osc1 osc2]
        end
      end
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
      set_ui_callbacks
    end

    def set_ui_callbacks
      @mix_panel.channels.each do |ch|
        ch.pitch_knob.add_callbacks(
            "call #{ch.name}_pitch"
        )
        ch.pitch_mode_button.add_callbacks(
            "call #{ch.name}_pitch"
        )
      end
    end

    def functions
      default_functions
      link_decays_function
      pitch_functions_mix
      pitch_function_main
      @functions
    end

    def osc_drift_function
      conf = @conf[:edit_buttons][:osc_drift]
      statements = [
        "$intensity := 0",
        "if($button_#{name}_osc_drift = 1)",
        "  $intensity := #{conf[:intensity]}",
        "end if"
      ]
      conf[:affected_keys].each do |aff_key_idx|
        @conf[:keys][aff_key_idx][:k_groups].each do |osc, k_groups|
          k_groups.each do |k_group|
            if conf[:modulator]
              modulator = "  find_mod(#{k_group},\"#{conf[:modulator]}\")"
            else
              modulator = "  -1"
            end
            if conf[:affected_oscs].include? osc.to_s
              statements << "  set_engine_par($ENGINE_PAR_MOD_TARGET_INTENSITY, $intensity, #{k_group}, #{modulator}, -1)"
            end
          end
        end
      end
      Ksp::Function.new("#{name}_osc_drift").append(statements)
    end

    def vel_start_function
      conf = @conf[:edit_buttons][:vel_start]
      statements = [
          "$intensity := 0",
          "if($button_#{name}_vel_start = 1)",
          "  $intensity := #{conf[:intensity]}",
          "end if"
      ]
      conf[:affected_keys].each do |aff_key_idx|
        @conf[:keys][aff_key_idx][:k_groups].each do |osc, k_groups|
          k_groups.each do |k_group|
            if conf[:modulator]
              modulator = "  find_mod(#{k_group},\"#{conf[:modulator]}\")"
            else
              modulator = "  -1"
            end
            if conf[:affected_oscs].include? osc.to_s
              statements << "  set_engine_par($ENGINE_PAR_MOD_TARGET_INTENSITY, $intensity, #{k_group}, #{modulator}, -1)"
            end
          end
        end
      end
      Ksp::Function.new("#{name}_vel_start").append(statements)
    end

    def xfade_function
      conf = @conf[:knobs].select{|knob| knob[:name] == @conf[:features][:xfade][:knob]}.first
      statements = []
      statements << "  $i := $knob_#{name}_#{@conf[:features][:xfade][:knob]}"
      statements << "  $i := ($i * $i * $i) + 320000"
      statements << "  $j := #{conf[:max_val]} - $knob_#{name}_#{@conf[:features][:xfade][:knob]}"
      statements << "  $j := ($j * $j * $j) + 320000"

      conf[:affected_keys].each do |aff_key_idx|
        @conf[:keys][aff_key_idx][:k_groups][:osc1].each do |k_group|
          statements << "  set_engine_par($ENGINE_PAR_VOLUME, $i, #{k_group}, -1, -1)"
        end
        @conf[:keys][aff_key_idx][:k_groups][:osc2].each do |k_group|
          statements << "  set_engine_par($ENGINE_PAR_VOLUME, $j, #{k_group}, -1, -1)"
        end
      end
      func = Ksp::Function.new("#{name}_xfade").append(statements)
      func.append(["message (\"setting volumes to \" & $i & \" and \" & $j & \" \")"])
    end

    def default_functions
      @functions += [
          osc_drift_function,
          vel_start_function,
          Ksp::Function.new("#{name}_vel_vca")
      ]
      @functions << xfade_function if @conf[:features][:xfade]
    end

    def ui_callbacks
      @mix_panel.channels.map do |ch|
        ch.pitch_knob.callbacks +
        ch.pitch_mode_button.callbacks
      end.flatten
    end

    def decay_function(conf)
      statements = []
      conf[:affected_keys].each do |aff_key_idx|
        @conf[:keys][aff_key_idx][:k_groups].each do |osc, k_groups|
          k_groups.each do |k_group|
            if conf[:modulator]
              modulator = "  find_mod(#{k_group},\"#{conf[:modulator]}\")"
            else
              modulator = "  -1"
            end
            if conf[:affected_oscs].include? osc.to_s
              statements << "  set_engine_par(#{conf[:parameter]}, $knob_#{name}_#{conf[:name]}, #{k_group}, #{modulator}, -1)"
            end
          end
        end
      end
      Ksp::Function.new("#{name}_#{conf[:name]}").append(statements)
    end

    def link_decays_function
      master_knob, master_function = nil, nil
      slave_knobs, slave_functions = [], []
      if @conf[:features].include? :link_decays
        @conf[:features][:link_decays][:knobs][0..1].each do |linked_knob_identifer|
          conf = @conf[:knobs].select { |knob| knob[:name] == linked_knob_identifer }.first
          @functions << decay_function(conf)
          if master_knob.nil?
            master_function = @functions.last.name
            master_knob = @main_panel.knobs.select{|knob| knob.name == "$knob_#{name}_#{conf[:name]}"}.first
          else
            slave_functions << @functions.last.name
            slave_knob = @main_panel.knobs.select{|knob| knob.name == "$knob_#{name}_#{conf[:name]}"}.first
            slave_knobs << slave_knob
          end
        end

        # -----------------------------------------------------------------------------------------
        # Link slaves to master
        statements = ["if ($button_#{name}_link_decays = 1)"]
        slave_knobs.each do |slave_knob|
          statements << "  #{slave_knob.name} := #{master_knob.name}"
        end
        statements += slave_functions.map{|slave_function| "  call #{slave_function}"}
        statements << "end if"
        @functions << Ksp::Function.new("#{name}_link_slave_decays").append(statements)
        # -----------------------------------------------------------------------------------------
        # Link master to slave
        statements = ["if ($button_#{name}_link_decays = 1)"]
        slave_knobs.each do |slave_knob|
          statements << "  #{master_knob.name} := #{slave_knob.name}"
        end
        statements << "  call #{master_function}"
        statements << "end if"
        @functions << Ksp::Function.new("#{name}_link_master_decay").append(statements)
      end
    end

    def pitch_functions_mix
      @mix_panel.channels.each_with_index do |ch, idx|
        @functions << Ksp::Function.new("#{ch.name}_pitch")
        statements = [" { message(\"#{@functions.last.name} got called\") } "]

        # -- If pitch is absolute...
        statements << "if (#{ch.pitch_mode_button.name} = 1) " # 0 means add value to key_group pitch, 1 means set absolute pitch
          # -- -- Set pitch for OSC1 - always!
          @conf[:keys][idx][:k_groups][:osc1].each do |k_group|
            statements << "  set_engine_par($ENGINE_PAR_TUNE, 500000 + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
          end
          # -- -- Set same pitch for OSC2 if feature is enabled AND pitch->osc button is active
          if @conf[:features][:pitch_osc2]
            statements << "  if ($button_#{@conf[:features][:pitch_osc2]} = 1)"
            @conf[:keys][idx][:k_groups][:osc2].each do |k_group|
              statements << "    set_engine_par($ENGINE_PAR_TUNE, 500000 + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
            end
            # -- -- Otherwise set pitch for OSC2 to 0
            statements << "  else"
            @conf[:keys][idx][:k_groups][:osc2].each do |k_group|
              statements << "    set_engine_par($ENGINE_PAR_TUNE, 500000 + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
            end
            statements << "  end if"
          end
        # -- else: pitch for key is added to key_group value (= relative)
        statements << "else"
          # -- -- Set pitch for OSC1 - always!
          @conf[:keys][idx][:k_groups][:osc1].each do |k_group|
            statements << "  set_engine_par($ENGINE_PAR_TUNE, $knob_#{name}_pitch + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
          end
          # -- -- Set same pitch for OSC2 if feature is enabled AND pitch->osc button is active
          if @conf[:features][:pitch_osc2]
            statements << "  if ($button_#{@conf[:features][:pitch_osc2]} = 1)"
            @conf[:keys][idx][:k_groups][:osc2].each do |k_group|
              statements << "    set_engine_par($ENGINE_PAR_TUNE, $knob_#{name}_pitch + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
            end
            # -- -- Otherwise set pitch for OSC2 to 0
            statements << "  else"
            @conf[:keys][idx][:k_groups][:osc2].each do |k_group|
              statements << "    set_engine_par($ENGINE_PAR_TUNE, 500000 + #{ch.pitch_knob.name}, #{k_group}, -1, -1)"
            end
            statements << "  end if"
          end
          statements << "end if"
        @functions.last.set_body(statements)
      end
    end

    def pitch_function_main
      body = @conf[:keys].map{|key| "call #{name}_#{key[:name]}_pitch" }
      @functions << Ksp::Function.new("#{name}_pitch").set_body(body)
    end

    def set_keys
      @conf[:keys].each do |key_conf|
        @keys << Beaotic::Key.new(key_conf)
      end
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

    def play_new_event(key_conf)
      statements = [
        "$#{name}_new_event := play_note($EVENT_NOTE, $#{name}_new_velocity, 0, -1)",
        "$volume := $knob_#{name}_level + $knob_#{name}_#{key_conf[:name]}_level"
      ]
      statements += [
          "if ($EVENT_VELOCITY >= #{@conf[:features][:accent][:velocity_threshold]})",
          "end if"
      ] if @conf[:features][:accent]
      statements += [
        "if ($button_#{name}_vel_vca = 1)",
        "    $volume := $volume + %velocity_db_mapping[$EVENT_VELOCITY] ",
        "end if",
        "change_vol($#{name}_new_event, $volume, 0)",
        "message(\"$volume was changed to \" & $volume )"
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
                play_new_event(key).map { |stm| '  ' + stm }
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
  end
end