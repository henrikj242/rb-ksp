module Beaotic
  class Diode < Ksp::UiSwitch
    def initialize(
      name:,
      visible: true
    )
      super(
        name:           "diode_#{name}",
        picture:        'diode',
        default_value:  0,
        visible:        visible
      )
    end
  end
end