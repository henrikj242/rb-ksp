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

class UiKnob
    def initialize(knob_conf) 
        @key_group_name = knob_conf[:key_group_name]
        @panel_name = knob_conf[:panel_name]
        @knob_name = knob_conf[:name]
        @min_val = knob_conf[:min_val]
        @max_val = knob_conf[:max_val]
        @default_val = knob_conf[:default_val]
        @affected_keys = knob_conf[:affected_keys]
        @modulator = knob_conf[:modulator]
        @parameter = knob_conf[:parameter]
        @function = knob_conf[:function]
    end
    
    def name
        "$knob_" + [@key_group_name, @panel_name, @knob_name].join('_')
    end    

    def declare
        "declare ui_slider #{name}(#{@min_val}, #{@max_val})"
    end

    def grpidx
        42
    end

    def callback
        return "" if @function == 'none'

        # Remember to actually iterate over affected_keys
        statement_body = ""
        if @function == 'bypass'
            if @modulator
                statement_body << "  $mod_idx := find_mod(#{grpidx}, \"#{@modulator}\") \n"
            else
                statement_body << "  $mod_idx := -1 \n"
            end
            statement_body << "  set_engine_par(#{@parameter}, #{name}, #{grpidx}, $mod_idx, -1) \n"
        end

        "on ui_control(#{name})\n" \
            "#{statement_body}" \
        "end on"
    end

    def function
    end
end

