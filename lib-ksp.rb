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

def parse_config(config_file = 'ksp.yml')
	y = YAML::load_file(File.join(__dir__, 'ksp.yml'))
	symbolize(y)
end

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

    class Variable
    end

    class Integer < Variable
        def self.declare(name, init_val)
            "declare #{name} := #{init_val}"
        end
    end

    class UiControl < Variable
        # make_persistent
        # set_position_px
        # show / hide
        # set_image stuff
    end

    class UiKnob < UiControl
        attr_accessor :k_groups

        def initialize(identifer, conf)
            @identifier = identifer
            @conf = conf
            @k_groups = { 
                osc1: [], 
                osc2: [] 
            }
        end
        
        def name
            "$knob_#{@identifier}"
        end

        def declare
            stmt = "declare ui_slider #{name}(#{@conf[:min_val]}, #{@conf[:max_val]})\n"
            if @conf[:modulator]
                stmt << Integer::declare("$mod_idx_#{@identifier}", 0)
                stmt << "\n"
            end
            stmt
        end

        def callback
            return "" if @conf[:function] == 'none'

            stmt = "on ui_control(#{name})\n"
            if @conf[:function] == 'bypass'
                k_groups.keys.each do |osc|
                    k_groups[osc].each do |k_group|
                        if @conf[:modulator]
                            stmt << "  $mod_idx_#{@identifier} := find_mod(#{k_group}, \"#{@conf[:modulator]}\") \n"
                        else
                            stmt << "  $mod_idx_#{@identifier} := -1 \n"
                        end
                        stmt << "  set_engine_par(#{@conf[:parameter]}, #{name}, #{k_group}, $mod_idx_#{@identifier}, -1) \n"
                    end
                end    
            elsif @conf[:function]
                stmt << "  call #{@conf[:function]}\n"
            end
            stmt << "end on\n"
        end
    end
end
