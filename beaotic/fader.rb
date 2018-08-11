module Beaotic
  class Fader < Ksp::UiSlider
    attr_reader :name, :label

    def initialize(
        name:,
        direction:        'horizontal',
        length:           64,
        label: nil,
        min_val:,
        default_val:,
        max_val:,
        mouse_behaviour:  900,
        visible: true
    )
      @label = Ksp::UiImage.new(
          name:     "label_#{name}",
          picture:  "label_#{label}",
          visible:  visible
      ) if label

      super(
          name:             "fader_#{name}",
          args:             [min_val, max_val],
          default_value:    default_val,
          visible:          visible,
          mouse_behaviour:  mouse_behaviour,
          picture:          "fader_#{direction}_#{length}"
      )
    end

    def hide
      super + "\n  " + @label&.hide.to_s
    end

    def show
      super + "\n  " + @label&.show.to_s
    end

    def label_offset(x = -17, y = -40)
      @label.xy(@x + x, @y + y)
    end
  end
end