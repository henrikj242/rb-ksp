def symbolize(obj)
  return obj.reduce({}) do |memo, (k, v)|
    memo.tap { |m| m[k.to_sym] = symbolize(v) }
  end if obj.is_a? Hash
    
  return obj.reduce([]) do |memo, v| 
    memo << symbolize(v); memo
  end if obj.is_a? Array
  
  obj
end

def parse_config(config_file = 'ksp.yml')
	y = YAML::load_file(File.join(__dir__, 'ksp.yml'))
	symbolize(y)
end

module Ksp
    class KeyGroup
        attr_writer :panels

        def initialize
            @panels = []
        end
        def panels
            @panels
        end
    end

    class UiPanel
        attr_writer :knobs

        def initialize
            @knobs = []
        end
        def knobs
            @knobs
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

    end

    class UiKnob < UiControl
        def initialize(knob_conf)
            @conf = knob_conf
        end
        
        def identifier
            [@conf[:key_group_name], @conf[:panel_name], @conf[:name]].join('_')
        end

        def name
            "$knob_" + identifier
        end    

        def declare
            stmt = "declare ui_slider #{name}(#{@conf[:min_val]}, #{@conf[:max_val]})\n"
            if @conf[:modulator]
                stmt << Integer::declare("$mod_idx_#{identifier}", 0)
                stmt << "\n"
            end
            stmt
        end

        def grpidx(affected_key)
            # TODO: Implement logic to figure out grp indexes
            42
        end

        def callback
            return "" if @conf[:function] == 'none'

            stmt = "on ui_control(#{identifier})\n"
            if @conf[:function] == 'bypass'
                @conf[:affected_keys].each do |affected_key|
                    if @conf[:modulator]
                        stmt << "  $mod_idx_#{identifier} := find_mod(#{grpidx(affected_key)}, \"#{@conf[:modulator]}\") \n"
                    else
                        stmt << "  $mod_idx_#{identifier} := -1 \n"
                    end
                    stmt << "  set_engine_par(#{@conf[:parameter]}, #{identifier}, #{grpidx(affected_key)}, $mod_idx_#{identifier}, -1) \n"
                end    
            end

            stmt << "end on\n"
        end

        def function
            stmt = ""
            @conf[:affected_keys].each do |affected_key|                
                indiv_knob = "$individ_knob_#{affected_key}_#{@conf[:name]}" # replace with smth like `get_indiv_knob_name(affected_key)`
                stmt << "function set_#{@conf[:key_group_name]}_#{affected_key}_#{@conf[:name]}\n" \
                    "  set_engine_par(#{@conf[:parameter]}, #{indiv_knob} + #{name}, #{grpidx(affected_key)}, -1, -1) \n" \
                    "end function \n"
            end
            stmt        
        end
    end
end
