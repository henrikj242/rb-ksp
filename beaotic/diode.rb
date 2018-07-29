module Beaotic
  class Diode < Ksp::UiSliderV2
    def initialize(
      name:,
      levels: 2,
      visible: true
    )
      super(
        name: "diode_#{name}",
        picture: 'diode',
        default_value: 0,
        args: [0, levels - 1],
        visible: visible
      )
    end
  end
end