module Beaotic
  class Knob < UiSlider
    attr_accessor :k_groups

    def initialize(identifier, conf)
      super(
        identifier,
        name: "knob_#{identifier}",

      )
      # @name = "$knob_#{@identifier}"
    end

    def declare
      statements = super
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"knob_48\")"
      statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_MOUSE_BEHAVIOUR, -500)"
    end

  end
end