module Ksp
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