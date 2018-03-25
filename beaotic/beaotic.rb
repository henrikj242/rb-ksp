module Beaotic
  $LOAD_PATH.unshift '../ksp/lib/'
  require 'ksp'

  class KeyGroup
    attr :knobs, :edit_buttons, :main_panel, :mix_panel, :title_image, :backdrops

    def initialize(key_group_conf)
      @conf = key_group_conf
      @knobs = []
      @edit_buttons = []
      set_title_image
      # set_backdrops
      set_main_panel
      set_mix_panel
    end

    def name
      @conf[:name]
    end

    def set_title_image
      @title_image = Ksp::UiImage.new("title_#{name}")
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
      ui_elements = @knobs.map(&:name) + @edit_buttons.map(&:name)
      ui_elements << @title_image.name
      ui_elements = ui_elements.map { |elem| sprintf("get_ui_id(%s)",elem) }
      @main_panel = "declare %panel_main_#{name}[#{ui_elements.count}] := (#{ui_elements.join(',')})"
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
        @knobs << Ksp::CustomKnob.new(knob_identifier, knob_conf)
        knob_conf[:affected_keys].each do |ak|
          if @knobs.last.label_exists?
            @knobs.last.label = Ksp::UiImage.new("label_#{knob_conf[:name]}")
          end
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
      pitch_functions + volume_functions
      # pan_functions
      # output_assign_functions
    end

    def functions
      default_functions
    end

    def volume_functions
      stmt = "{ default volume functions }\n"
      @conf[:keys].each do |affected_key|
        stmt << mix_volume_function(affected_key)
      end

      stmt << "function set_volume_#{@conf[:name]}\n"
      @conf[:keys].each do |affected_key|
        stmt << "  call set_volume_#{@conf[:name]}_#{affected_key[:name]} \n"
      end
      stmt << "end function \n"
    end

    def mix_volume_function(affected_key)
      main_knob = "$knob_volume_#{@conf[:name]}"
      mix_knob = "$knob_volume_#{@conf[:name]}_#{affected_key[:name]}"

      stmt = "function set_volume_#{@conf[:name]}_#{affected_key[:name]} \n"
      affected_key[:k_groups].keys.each do |osc|
        affected_key[:k_groups][osc].each do |k_group|
          stmt << "  set_engine_par($ENGINE_PAR_VOLUME, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1) \n"
        end
      end
      stmt << "end function\n"
    end

    def mix_pitch_function(affected_key)
      main_knob = "$knob_pitch_#{@conf[:name]}"
      mix_knob = "$knob_pitch_#{@conf[:name]}_#{affected_key[:name]}"

      stmt = "function set_pitch_#{@conf[:name]}_#{affected_key[:name]} \n"
      affected_key[:k_groups].keys.each do |osc|
        affected_key[:k_groups][osc].each do |k_group|
          stmt << "  set_engine_par($ENGINE_PAR_TUNE, #{mix_knob} + #{main_knob}, #{k_group}, -1, -1) \n"
        end
      end
      stmt << "end function\n"
    end

    def pitch_functions
      stmt = "{ default pitch functions }\n"
      @conf[:keys].each do |affected_key|
        stmt << mix_pitch_function(affected_key)
      end

      stmt << "function set_pitch_#{@conf[:name]}\n"
      @conf[:keys].each do |affected_key|
        stmt << "  call set_pitch_#{@conf[:name]}_#{affected_key[:name]} \n"
      end
      stmt << "end function \n"
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
