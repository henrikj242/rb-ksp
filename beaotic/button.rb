module Beaotic
  class Button < Ksp::UiSwitch
    def initialize(
      name:,
      persistent:     true,
      default_value:  0,
      visible:        true,
      picture:
    )
      super(
        name:           name,
        persistent:     persistent,
        default_value:  default_value,
        visible:        visible,
        picture:        picture
      )
    end
  end
end