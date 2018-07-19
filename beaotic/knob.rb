module Beaotic
  class Knob < Ksp::UiSliderV2
    attr_reader :name, :label

    def initialize(
        name:,
        diameter: 48,
        label:,
        min_val:,
        default_val:,
        max_val:,
        mouse_behaviour: -500,
        visible: true
    )
      @label = Ksp::UiImage.new(
          name:     "label_#{name}",
          picture:  "label_#{label}",
          visible:  visible
      )
      super(
        name: name,
        args: [min_val, max_val],
        default_value: default_val,
        visible: visible,
        mouse_behaviour: mouse_behaviour,
        picture: "knob_#{diameter}"
      )
    end

    def hide
      super + "\n  " + @label.hide
    end

    def show
      super + "\n  " + @label.show
    end

    def label_offset(x = -17, y = -40)
      @label.xy(@x + x, @y + y)
    end

    def statements
      super
    end
  end
end