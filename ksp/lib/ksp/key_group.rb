module Ksp
  class KeyGroup
    attr :knobs, :main_panel

    def initialize(key_group_conf)
      @conf = key_group_conf
      @knobs = []
      @buttons = []
      set_main_panel
      set_mix_panel
    end

    def name
      @conf[:name]
    end

    def set_main_panel
      set_knobs
      set_buttons
      main_panel
    end

    def main_panel
      # return a ksp statement that adds all the ui_id's to a ksp array
      ui_elements = @knobs.map(&:name) + @buttons.map(&:name)
      ui_elements = ui_elements.map { |elem| sprintf("get_ui_id(%s)",elem) }
      @main_panel = "declare %panel_main_#{name}[#{ui_elements.count}] := (#{ui_elements.join(',')})"
    end

    def set_mix_panel
      @conf[:keys].each do |key_conf|
        identifier = "#{name}_#{key_conf[:name]}"

      # define level fader
      # define pan fader
      # define pitch knob
      # define output menu
      # diode
      end
    end

    def set_knobs
      @conf[:knobs].each do |knob_conf|
        knob_identifier = "#{name}_#{knob_conf[:name]}"
        @knobs << CustomKnob.new(knob_identifier, knob_conf)
        knob_conf[:affected_keys].each do |ak|
          @knobs.last.k_groups[:osc1] += @conf[:keys][ak][:k_groups][:osc1]
          if @conf[:keys][ak][:k_groups][:osc2]
            @knobs.last.k_groups[:osc2] += @conf[:keys][ak][:k_groups][:osc2]
          end
        end
      end
    end

    def set_buttons

    end

    def default_functions
      pitch_functions
      # level_functions
      # pan_functions
      # output_assign_functions
    end

    def functions
      default_functions
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
      stmt = "{{ default pitch functions }}\n"
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
end
