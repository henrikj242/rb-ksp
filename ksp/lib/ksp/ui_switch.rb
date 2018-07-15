module Ksp
  class UiSwitch < UiControl
    def initialize(
          name:,
          persistent:     true,
          default_value:  nil,
          visible:        true,
          picture:        nil
    )
      super(
        type:           'ui_switch',
        name:           name,
        persistent:     persistent,
        default_value:  default_value,
        visible:        visible,
        picture:        picture
      )
    end
  end
end