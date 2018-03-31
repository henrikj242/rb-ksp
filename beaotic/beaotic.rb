module Beaotic
  $LOAD_PATH.unshift '../ksp/lib/'
  require 'ksp'

  class KeyGroup
    attr :conf, :knobs, :edit_buttons, :mix_panel, :title_image, :backdrops, :keys, :round_robin_entries

    def initialize(key_group_conf)
      @gui_directory = '_gui'
      @conf = key_group_conf
      @knobs = []
      @edit_buttons = []
      @main_panel_name = "%panel_main_#{name}"
      @main_panel_elements = []
      @round_robin_entries = @conf[:features][:round_robin][:entries] rescue 1
      @keys = []
      set_title_image
      # set_backdrops
      set_main_panel
      set_mix_panel

      set_keys
    end

    def name
      @conf[:name]
    end

    def set_title_image
      @title_image = Ksp::UiImage.new("title_#{name}", image: "title_#{name}")
    end

    # def set_backdrops
    #   @backdrops = []
    #   @backdrops << Ksp::UiImage.new("img_buttons_backdrop_short")
    #   @backdrops.last.image_size = { width: 10, height: 33 }
    #   @backdrops << Ksp::UiImage.new("img_buttons_backdrop")
    #   @backdrops.last.image_size = { width: 650, height: 33 }
    # end

    def set_main_panel
      set_knobs
      set_edit_buttons
      main_panel
    end

    # a ksp statement that adds all the ui_id's to a ksp array
    def main_panel
      @main_panel_elements = @knobs.map(&:name) + @knobs.map{ |knob| knob.label.name if knob.label } + @edit_buttons.map(&:name)
      @main_panel_elements << @title_image.name
    end

    def main_panel_declare
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
      end
    end

    def set_edit_buttons
      @conf[:edit_buttons].each do |k, v|
        button_identifier = "#{name}_#{k}"
        v = v.merge(image: "button_#{k}")
        @edit_buttons << Ksp::CustomButton.new(button_identifier, v)
      end
    end

    def default_functions
      pitch_functions
      # volume_functions
      # pan_functions
      # output_assign_functions
    end

    def functions
      default_functions
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

    def set_keys
      extra_options = {
          key_group_name: name
      }
      extra_options[:features] = @conf[:features] if @conf[:features]

      @conf[:keys].each do |key|
        @keys << Beaotic::Key.new(self, key.merge(extra_options))
        @keys.last.set_callback()
      end
    end
  end

  class Key
    attr :midi_note, :name, :callback, :callback_function
    def initialize(key_group, conf)
      @key_group = key_group
      @conf = conf
      @midi_note = conf[:midi_note]
      @name = conf[:name]
      # @callback_function = []
      @callback = []
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
    # 3: For groups with more than 12 color variations, we are forced to use additional Kontakt groups.
    #
    # As long as we don't use more than 32 color variations, we always split colors across velocity.
    #
    #
    #
    #

    def disallow_groups
      statements = []
      @conf[:k_groups].keys.each do |osc|
        @conf[:k_groups][osc].map { |k_group_id| statements << "disallow_group(#{k_group_id})"}
      end
      statements
    end

    def allow_groups
      statements = []

      # if @conf[:features] && @conf[:features][:osc2_color]
      #
      # end
      @conf[:k_groups][:osc1].map { |k_group_id| statements << "allow_group(#{k_group_id})"}
      # @conf[:k_groups].keys.each do |osc|
      #   @conf[:k_groups][osc].map { |k_group_id| statements << "allow_group(#{k_group_id})"}
      # end
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
      (splits.to_i * 2).to_s unless @conf[:features][:accent_switch].nil?
    end

    def osc2_color_conf
      @key_group.conf[:knobs].select{ |k| k[:name] == @conf[:features][:osc2_color] }.first
    end

    def set_callback
      @callback << "if ($EVENT_NOTE = #{midi_note})"

      disallow_groups.map { |statement| @callback << '  ' + statement }
      allow_groups.map { |statement| @callback << '  ' + statement }

      if @conf[:features] && @conf[:features][:round_robin]
        @callback << "{ RR Mode: #{@conf[:features][:round_robin][:mode]} }"
        @callback << " $#{@conf[:key_group_name]}_round_robin_next := ($#{@conf[:key_group_name]}_round_robin_next+1) mod $#{@conf[:key_group_name]}_round_robin_max"
        case @conf[:features][:round_robin][:mode]
          when 'group'
            if @conf[:features][:osc2_color]
              @callback << "{ color_max #{osc2_color_conf[:max_val]} }"
            end
          when 'velocity'
            # if @conf[:features][:osc2_color] ## NOT YET SUPPORTED FOR VELOCITY SPLIT
            #   @callback << "{ color_max #{osc2_color_conf[:max_val]} }"
            #   @callback << "{ velocity_split_list:  #{Ksp::Utility.velocity_split_list(split_count)} }"
            # else
              @callback << "  if ($EVENT_VELOCITY < #{@conf[:features][:accent_switch]})"
              @callback << "    $#{@conf[:key_group_name]}_new_velocity := %velocity_splits_#{split_count}[$#{@conf[:key_group_name]}_round_robin_next]"
              @callback << '  else'
              @callback << "    $#{@conf[:key_group_name]}_new_velocity := %velocity_splits_#{split_count}[$#{@conf[:key_group_name]}_round_robin_next + #{@conf[:features][:round_robin][:entries]}]"
              @callback << '  end if'
              @callback << "  change_velo($EVENT_ID, $#{@conf[:key_group_name]}_new_velocity)"
            # end
        end
      end

      # if @conf[:features] && @conf[:features][:accent_switch]
      #   @callback << "  if ($EVENT_VELOCITY >= #{@conf[:features][:accent_switch]})"
      #   @callback << '  end if'
      # end
      @callback << 'end if'
    end
  end

  class Image
    def initialize
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
                                  horizontal_resizable: 'yes'
                       when 'title', 'label'
                         template number_of_animations: 1
                       when 'button'
                         template number_of_animations: 6
                       when 'knob'
                         template number_of_animations: 101
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
