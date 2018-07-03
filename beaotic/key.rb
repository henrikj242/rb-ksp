module Beaotic
  class Key
    attr :midi_note, :name, :callback, :off_callback
    def initialize(key_group, idx, conf)
      @key_group = key_group
      @idx = idx
      @conf = conf
      @midi_note = conf[:midi_note]
      @name = conf[:name]
      @callback = []
      @off_callback = []
    end

    # There are a few ways we can support round robin and the "color" setting.
    #
    # 1: For groups with no color setting we can simply split the round robin entries out across the velocity range
    # This implies the ones without accent being assigned to velocities below 64, and the ones with accent being
    # assigned to velocities 64 and up.
    #
    # 2: For groups with a few color variants (up to 12) we can also use velocity splitting, as this will result in
    # 120 samples - so less than 128.
    #
    # 3: For groups with more than 12 color variations, as long as we also have 5 RR-entries and Accent, we are
    # forced to use additional Kontakt groups.
    #
    # As long as we don't use more than 64 color variations and Accent, we always split colors across velocity.
    #


    def set_k_groups
      statements = ["{ setting k_groups }"]
      @conf[:k_groups].keys.each do |osc|
        statements << "declare %#{@conf[:key_group_name]}_#{name}_k_groups_#{osc}[#{@conf[:k_groups][osc].count}] := (#{@conf[:k_groups][osc].join(', ')})"
      end
      statements
    end

    def disallow_groups
      statements = []
      @conf[:k_groups].keys.each do |osc|
        @conf[:k_groups][osc].map { |k_group_id| statements << "disallow_group(#{k_group_id})"}
      end
      statements
    end

    def allow_groups(osc = :osc1)
      statements = []
      @conf[:k_groups][osc].map do |k_group_id|
        statements << "allow_group(#{k_group_id})"
      end
      statements
    end

    def set_decay
      statements = []
      # find knobs with callback: 'decay' and affected_keys including me based on my midi_note and idx
      knobs = @key_group.knobs.select{ |k| k.conf[:callback] == 'decay' && k.conf[:affected_keys].include?(@idx) }
      knobs.each do |knob|
        knob.conf[:affected_oscs].each do |affected_osc|
          @conf[:k_groups][affected_osc.to_sym].each do |k_group|
            statements << "set_engine_par(#{knob.conf[:parameter]}, #{knob.name}, #{k_group}, find_mod(#{k_group}, \"#{knob.conf[:modulator]}\"), -1)"
          end
        end
      end
      statements
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

    def osc2_color_conf
      @key_group.conf[:knobs].select{ |k| k[:name] == @conf[:features][:osc2_color] }.first
    end

    # Round Robin and our Color-concept become quite intertwined, as also mentioned in comment above.
    # TODO: Make prettier!

    def set_callback
      @callback << "if ($EVENT_NOTE = #{midi_note})"
      @callback << "  @#{@key_group.name}_message := \"\""
      set_decay.map{ |statement| @callback << '  ' + statement }

      # We can use the change_vol function to relatively change the volume of the individual event for Accent-strikes
      if @conf.fetch(:features, {}).fetch(:accent, {}) != {}
        @callback << "  if ($EVENT_VELOCITY >= #{@conf[:features][:accent][:velocity_threshold]})"
        @callback << "    #{@key_group.diode.name} := 2" if @key_group.diode
        @callback << "  else"
        @callback << "    #{@key_group.diode.name} := 1" if @key_group.diode
        @callback << '  end if'
      end

      if @conf.fetch(:features, {}).fetch(:midi_select, {}) != {}
        @callback << "  if ($button_#{@conf[:features][:midi_select][:group_selector]} = 1)"
        @callback << "    $selected_group := #{@key_group.conf[:index]}"
        @callback << "    call #{@conf[:features][:midi_select][:function].gsub('KEY_GROUP', @key_group.name)}"
        @callback << '  end if'
      end

      if @conf.fetch(:features, {}).fetch(:round_robin, {}) != {}
        @callback << " $#{@key_group.name}_round_robin_next := ($#{@key_group.name}_round_robin_next+1) mod $#{@key_group.name}_round_robin_max"

        if @conf[:features][:round_robin][:mode].include?('group')
          if @conf[:features][:osc2_color] # TODO: Seems like we should have an else branch for this
            disallow_groups.map{ |statement| @callback << '  ' + statement }
            @callback << "{ color_max #{osc2_color_conf[:max_val]} }"
            @callback << "  if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})"
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count(:color)}[$knob_#{@key_group.name}_#{osc2_color_conf[:name]} - 1]"
            @callback << '  else'
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count(:color)}[$knob_#{@key_group.name}_#{osc2_color_conf[:name]}  - 1 + #{osc2_color_conf[:max_val]}]"
            @callback << '  end if'
            @callback << "  allow_group(%#{@key_group.name}_#{name}_k_groups_osc2[$#{@key_group.name}_round_robin_next])"
            @callback << "  $#{@key_group.name}_new_event := play_note($EVENT_NOTE, $#{@key_group.name}_new_velocity, 0, -1)"
            @callback << "  change_vol($#{@key_group.name}_new_event, $fader_accent, 0)"
            @callback << "  wait(1)"
            @callback << "  @#{@key_group.name}_message := \"osc2: \" & get_event_par($#{@key_group.name}_new_event, $EVENT_PAR_ZONE_ID)"
          end
        end
        if @conf[:features][:round_robin][:mode].include?('velocity')
          disallow_groups.map{ |statement| @callback << '  ' + statement }
          allow_groups(:osc1).map{ |statement| @callback << '  ' + statement }
          @callback << "  if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})"
          @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count(:round_robin)}[$#{@key_group.name}_round_robin_next]"
          @callback << '  else'
          @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count(:round_robin)}[$#{@key_group.name}_round_robin_next + #{@conf[:features][:round_robin][:entries]}]"
          @callback << '  end if'
          @callback << "  $#{@key_group.name}_new_event := play_note($EVENT_NOTE, $#{@key_group.name}_new_velocity, 0, -1)"
          @callback << "  change_vol($#{@key_group.name}_new_event, $fader_accent, 0)"
          @callback << "  wait(1)"
          @callback << "  @#{@key_group.name}_message := @#{@key_group.name}_message & \" osc1: \" & get_event_par($#{@key_group.name}_new_event, $EVENT_PAR_ZONE_ID)"
        end
        @callback << "  message(@#{@key_group.name}_message)"
        @callback << "  change_note($EVENT_ID, 0)"
      end
      @callback << 'end if'
    end

    def set_off_callback
      @off_callback << "if ($EVENT_NOTE = #{midi_note})"
      @off_callback << "  #{@key_group.diode.name} := 0" if @key_group.diode
      @off_callback << 'end if'
    end
  end
end