module Ksp
  class CustomKnob < UiSlider
    attr_accessor :k_groups, :label
    attr_reader :name

    def initialize(identifer, conf)
      @directory = '_gui'
      @identifier = identifer
      @name = "$knob_#{@identifier}"
      @conf = conf
      @k_groups = {
          osc1: [],
          osc2: []
      }
    end

    # def label_exists?
    #   File.exists?(label_file)
    # end
    #
    # def label_file
    #   "#{@directory}/label_#{@conf[:name]}.png"
    # end

    def label=(ui_image)
      @label = ui_image
    end

    def declare
      statements = []
      statements << "{ #{name} }"
      statements << "declare ui_slider #{name}(#{@conf[:min_val]}, #{@conf[:max_val]})"
      if @conf[:modulator]
        statements << Integer::declare("$mod_idx_#{@identifier}", 0)
      end
      statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_DEFAULT_VALUE, #{@conf[:default_val]})"
      statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_VALUE, #{@conf[:default_val]})"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_NAME, \"#{@identifier}\")"
      # set_control_par(get_ui_id($knob_pitch),$CONTROL_PAR_AUTOMATION_ID,$host_auto_id)
      # inc($host_auto_id)
      statements << "make_persistent(#{name})"
      # statements << "hide_part(#{name},$HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      statements << "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"knob_48\")"
      statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_MOUSE_BEHAVIOUR, -500)"
      statements
    end

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
    end

    def function
      if @conf[:function]
        return [] if @conf[:function] == 'none' || @conf[:function].match(/^KEY_GROUP_/)
      end
      statements = []
      statements << "function #{@identifier}"
      statements << 'end function'
      statements
    end

    def callback
      return [] if @conf[:function] == 'none'

      statements = ["on ui_control(#{name})"]
      message = "callback: #{name}"
      if @conf[:function] == 'bypass'
        k_groups.keys.each do |osc|
          k_groups[osc].each do |k_group|
            if @conf[:modulator]
              message += " modulator: #{@conf[:modulator]}"
              statements << "  $mod_idx_#{@identifier} := find_mod(#{k_group}, \"#{@conf[:modulator]}\")"
            else
              statements << "  $mod_idx_#{@identifier} := -1"
            end
            message += " param: #{@conf[:parameter]}"
            statements << "  set_engine_par(#{@conf[:parameter]}, #{name}, #{k_group}, $mod_idx_#{@identifier}, -1)"
          end
        end
      elsif @conf[:function]
        statements << "  call #{@conf[:function].gsub(/^KEY_GROUP/, @conf[:key_group_name])}"
      else
        statements << "  call #{@identifier}"
      end
      # statements << "message (\"#{message}\")"
      statements << 'end on'
      statements
    end
  end
end