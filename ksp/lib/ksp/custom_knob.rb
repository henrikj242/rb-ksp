module Ksp
  class CustomKnob < UiSlider
    attr_accessor :k_groups
    attr_reader :name

    def initialize(identifer, conf)
      @identifier = identifer
      @name = "$knob_#{@identifier}"
      @conf = conf
      @k_groups = {
          osc1: [],
          osc2: []
      }
    end

    def declare
      stmt = []
      stmt << "{ #{name} }"
      stmt << "declare ui_slider #{name}(#{@conf[:min_val]}, #{@conf[:max_val]})"
      if @conf[:modulator]
        stmt << Integer::declare("$mod_idx_#{@identifier}", 0)
      end
      stmt << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_DEFAULT_VALUE, #{@conf[:default_val]})"
      stmt << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_VALUE, #{@conf[:default_val]})"
      stmt << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_NAME, \"#{@identifier}\")"
      # set_control_par(get_ui_id($knob_pitch),$CONTROL_PAR_AUTOMATION_ID,$host_auto_id)
      # inc($host_auto_id)
      stmt << "make_persistent(#{name})"
      stmt << "hide_part(#{name},$HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      stmt << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"knob_48\")"
      stmt << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_MOUSE_BEHAVIOUR, -500)"
    end

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
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