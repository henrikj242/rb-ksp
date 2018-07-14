module Beaotic
  class Knob < Ksp::UiSliderV2
    attr_reader :name, :label

    def initialize(name:, diameter: 48, label:, min_val:, default_val:, max_val:)
      super(name: name, args: [min_val, max_val], default_value: default_val)
      @picture = "knob_#{diameter}"
      @label = Ksp::UiImage.new(name: "label_#{name}", image: "label_#{label}")
    end
  end
end