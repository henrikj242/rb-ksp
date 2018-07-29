module Ksp
  class UiSlider < UiControl

    def initialize(
          name:,
          args:             nil,
          default_value:    nil,
          visible:          true,
          mouse_behaviour:  1000,
          picture:          nil
    )
      super(
          type:           'ui_slider',
          name:           name,
          args:           args,
          default_value:  default_value,
          visible:        visible,
          picture:        picture
      )
      @mouse_behaviour = mouse_behaviour
    end

    def statements
      super + ["set_control_par(get_ui_id(#{name}), $CONTROL_PAR_MOUSE_BEHAVIOUR, #{@mouse_behaviour})"]
    end
  end
end