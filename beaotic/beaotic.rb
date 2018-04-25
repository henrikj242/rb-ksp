module Beaotic
  $LOAD_PATH.unshift '../ksp/lib/'
  require 'ksp'

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

    def functions
      default_functions + feature_functions
    end

    def set_mix_panel
      @volume_faders = []
      @pan_faders = []
      @pitch_knobs = []
      @conf[:keys].each do |key_conf|
        @volume_faders << Ksp::VolumeFader.new(name, key_conf)
        # @pan_faders << PanFader.new(name, key_conf)
        # pitch knob
        # output menu
        # diode
      end
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
      pitch_functions
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
      affected_key[:k_groups].keys.each do |osc|
        affected_key[:k_groups][osc].each do |k_group|
          statements << "  set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1)"
        end
      end
      statements << "end function"
      statements
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
      statements
    end

    def feature_functions
      statements = []
      # if @conf[:features].include?(:osc2_decay)
      #   osc2_decay_function.map{ |statement| statements << statement }
      # end
      if @conf[:features].include?(:link_decays)
        link_decays_functions.map{ |statement| statements << statement }
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

    # def osc2_decay_function
    #   decay_knob = @knobs.select{ |knob| knob.identifier == "#{name}_decay" }.first
    #   osc2_decay_knob = @knobs.select{ |knob| knob.identifier == "#{name}_#{@conf[:features][:osc2_decay]}" }.first
    #   osc2_link_decays_button = @edit_buttons.select{ |button| button.identifier == "#{name}_link_decays" }.first
    #
    #   statements = [" { osc2_decay_function here. source var: #{osc2_decay_knob.name} } "]
    #   statements << "function #{osc2_decay_knob.identifier}"
    #   statements << "  if (#{osc2_link_decays_button.name} = 1)"
    #   statements << "    #{decay_knob.name} := #{osc2_decay_knob.name}"
    #   statements << "  end if"
    #   # @conf[:k_groups][:osc2].each do |k_group|
    #   #   statements << "  $mod_idx_#{@identifier} := find_mod(#{k_group}, \"#{@conf[:modulator]}\")"
    #   #   @conf[:k_groups][osc2].map { |k_group| statements << "  set_engine_par(#{@conf[:parameter]}, #{name}, #{k_group}, $mod_idx_#{@identifier}, -1)" "disallow_group()"}
    #   # end
    #
    #   statements << 'end function'
    #   statements
    # end

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
  end

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
      # puts @conf.inspect
      # exit
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

    def allow_groups
      statements = []
      @conf[:k_groups][:osc1].map do |k_group_id|
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

    def split_count
      splits = if @conf[:features][:osc2_color] && @conf[:features][:round_robin] && @conf[:features][:round_robin][:mode] == 'group'
        osc2_color_conf[:max_val]
      elsif @conf[:features][:osc2_color] && @conf[:features][:round_robin] && @conf[:features][:round_robin][:mode] == 'velocity'
        # not yet supported
      elsif @conf[:features][:round_robin] && @conf[:features][:round_robin][:mode] == 'velocity'
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
      set_decay.map{ |statement| @callback << '  ' + statement }

      # We can use the change_vol function to relatively change the volume of the individual event for Accent-strikes
      if @conf.fetch(:features, {}).fetch(:accent, {}) != {}
      # if @conf[:features] && @conf[:features][:accent][:velocity_threshold]
        @callback << "  if ($EVENT_VELOCITY >= #{@conf[:features][:accent][:velocity_threshold]})"
        @callback << '    change_vol($EVENT_ID, $fader_accent, 0)'
        @callback << "    #{@key_group.diode.name} := 2" if @key_group.diode
        @callback << "  else"
        @callback << "    #{@key_group.diode.name} := 1" if @key_group.diode
        @callback << '  end if'
      end

      if @conf.fetch(:features, {}).fetch(:midi_select, {})
        @callback << "  if ($button_#{@conf[:features][:midi_select][:group_selector]} = 1)"
        @callback << "    $selected_group := #{@key_group.conf[:index]}"
        @callback << "    call #{@conf[:features][:midi_select][:function].gsub('KEY_GROUP', @key_group.name)}"
        # @callback << "    $button_#{@conf[:features][:midi_select][:group_selector]} := 0"
        @callback << '  end if'
      end

      if @conf.fetch(:features, {}).fetch(:round_robin, {}) != {}
        @callback << "{ RR Mode: #{@conf[:features][:round_robin][:mode]} }"
        @callback << " $#{@key_group.name}_round_robin_next := ($#{@key_group.name}_round_robin_next+1) mod $#{@key_group.name}_round_robin_max"
        case @conf[:features][:round_robin][:mode]
        when 'group'
          if @conf[:features][:osc2_color]
            disallow_groups.map{ |statement| @callback << '  ' + statement }
            allow_groups.map{ |statement| @callback << '  ' + statement }

            @callback << "{ color_max #{osc2_color_conf[:max_val]} }"
            @callback << "  if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})"
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count}[($knob_#{@key_group.name}_#{osc2_color_conf[:name]})-1]"
            @callback << '  else'
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count}[($knob_#{@key_group.name}_#{osc2_color_conf[:name]} + #{osc2_color_conf[:max_val]})-1]"
            @callback << '  end if'
            @callback << "  change_velo($EVENT_ID, $#{@key_group.name}_new_velocity)"
            @callback << "  allow_group(%#{@key_group.name}_#{name}_k_groups_osc2[$#{@key_group.name}_round_robin_next])"
          end
        when 'velocity'
            # @conf[:features][:osc2_color] NOT YET SUPPORTED FOR VELOCITY-BASED ROUND-ROBIN
            @callback << "  if ($EVENT_VELOCITY < #{@conf[:features][:accent][:velocity_threshold]})"
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count}[$#{@key_group.name}_round_robin_next]"
            @callback << '  else'
            @callback << "    $#{@key_group.name}_new_velocity := %velocity_splits_#{split_count}[$#{@key_group.name}_round_robin_next + #{@conf[:features][:round_robin][:entries]}]"
            @callback << '  end if'
            @callback << "  change_velo($EVENT_ID, $#{@key_group.name}_new_velocity)"
        end
      end
      @callback << 'end if'
    end

    def set_off_callback
      @off_callback << "if ($EVENT_NOTE = #{midi_note})"
      @off_callback << "  #{@key_group.diode.name} := 0" if @key_group.diode
      @off_callback << 'end if'
    end
  end

  class Image
    def initialize(conf)
      @conf = conf
      @directory = '_gui'
    end

    def generate_txt_files
      image_file_names.each do |name|
        image_type = name.split('_').first
        content = content(image_type)
        if content.length > 0
          File.open("#{@directory}/#{name}.txt", 'w') do |f|
            f.write(content)
          end
        end
      end
    end

    def image_file_names
      image_file_names = []
      Dir.foreach(@directory) do |item|
        next if item == '.' or item == '..'
        if item.match(/\.txt/)
          File.unlink("#{@directory}/#{item}")
        elsif item.match(/\.png/)
          image_file_names << File.basename(item, '.png')
        end
      end
      image_file_names
    end

    def content(image_type)
      content_hash = case image_type
                     when 'img'
                       template vertical_resizable: 'yes',
                                horizontal_resizable: 'yes',
                                number_of_animations: 1
                     when 'title', 'label'
                       template number_of_animations: 1
                     when 'diode'
                       template number_of_animations: 3
                     when 'button'
                       template number_of_animations: 6
                     when 'fader'
                       template number_of_animations: 41
                     when 'knob'
                       template number_of_animations: 101
                     when 'wallpaper'
                       template number_of_animations: @conf[:wallpaper_animations]
                     else
                       {}
                     end
      output = ''
      content_hash.map do |k, v|
        output << k.to_s.split('_').map do |word|
            if %w(of).include?(word)
              word
            else
              word.capitalize
            end
        end.join(' ') + ": #{v}\n"
      end
      output
    end

    def template(options = {})
      {
        has_alpha_channel: options[:has_alpha_channel] || 'yes',
        number_of_animations: options[:number_of_animations] || 1,
        horizontal_animation: options[:horizontal_animation] || 'no',
        vertical_resizable: options[:vertical_resizable] || 'no',
        horizontal_resizable: options[:horizontal_resizable] || 'no',
        fixed_top: options[:fixed_top] || 0,
        fixed_bottom: options[:fixed_bottom] || 0,
        fixed_left: options[:fixed_left] || 0,
        fixed_right: options[:fixed_right] || 0,
      }
    end
  end
end
