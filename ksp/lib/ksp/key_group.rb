module Ksp
  class KeyGroup
    attr :knobs

    def initialize(key_group_conf)
      @conf = key_group_conf
      @knobs = []
      set_knobs
    end

    def name
      @conf[:name]
    end

    def set_knobs
      knobs = []
      @conf[:knobs].each do |knob_conf|
        knob_identifier = "#{@conf[:name]}_#{knob_conf[:name]}"
        @knobs << UiKnob.new(knob_identifier, knob_conf)
        knob_conf[:affected_keys].each do |ak|
          @knobs.last.k_groups[:osc1] += @conf[:keys][ak][:k_groups][:osc1]
          if @conf[:keys][ak][:k_groups][:osc2]
            @knobs.last.k_groups[:osc2] += @conf[:keys][ak][:k_groups][:osc2]
          end
        end
      end
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
