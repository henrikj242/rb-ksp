module Beaotic
  class Knob < Ksp::UiSliderV2
    attr_reader :name, :label

    def initialize(name:, diameter: 48, label:, min_val:, default_val:, max_val:)
      super(name: name, args: [min_val, max_val],
            default_value: default_val, visible: true)
      @picture = "knob_#{diameter}"
      @label = Ksp::UiImage.new(name: "label_#{name}", picture: "label_#{label}")
    end

    def label_offset(x = 0, y = -16)
      @label.xy(@x + x, @y + y)
    end

    def statements
      super + @label.statements
    end
  end
end