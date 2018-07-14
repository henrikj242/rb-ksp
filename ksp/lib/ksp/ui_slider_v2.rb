module Ksp
  class UiSliderV2 < UiControl
    # attr_accessor :label
    # attr_reader :name, :identifier, :conf

    def initialize(name:, args: nil, default_value: nil, visible: true)
      super(
          type: 'ui_slider',
          name: name,
          args: args,
          default_value: default_value,
          visible: visible
      )

      # @directory = '_gui'
      # @identifier = identifer
      # @conf = conf
      # @k_groups = {
      #     osc1: [],
      #     osc2: []
      # }
    end


    # def declare
    #   statements = []
    #   statements << "{ #{name} }"
    #   statements << "declare ui_slider #{name}(#{@conf[:min_val]}, #{@conf[:max_val]})"
    #   if @conf[:modulator]
    #     statements << Integer::declare("$mod_idx_#{@identifier}", 0)
    #   end
    #   statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_DEFAULT_VALUE, #{@conf[:default_val]})"
    #   statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_VALUE, #{@conf[:default_val]})"
    #   statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_NAME, \"#{@identifier}\")"
    #   # set_control_par(get_ui_id($knob_pitch),$CONTROL_PAR_AUTOMATION_ID,$host_auto_id)
    #   # inc($host_auto_id)
    #   statements << "make_persistent(#{name})"
    #   statements << "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
    #   # statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"knob_48\")"
    #   statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_MOUSE_BEHAVIOUR, #{@conf[:ui_control][:mouse_behaviour]})"
    #   statements
    # end
  end
end