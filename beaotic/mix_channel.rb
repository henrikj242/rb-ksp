module Beaotic
  class MixChannel
    attr_accessor :elements

    def initialize(name, base_x)
      @name = name
      @base_x = base_x
      @elements = []
    end

    def set_title_image
      title_img = Ksp::UiImage.new(
        name:     "title_mix_#{@name}",
        picture:  "title_mix_#{@name}"
      )
      title_img.xy(@base_x + 5, 0)
      title_img
    end

    def set_pitch_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name: "knob_#{@name}_pitch",
        diameter: 44,
        label: "pitch",
        min_val: min_val,
        default_val: default_val,
        max_val: max_val,
        visible: false
      )
      knob.xy(@base_x + 22, 46)
      knob.label_offset(-16, -16)
      knob
    end

    def set_level_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name: "knob_#{@name}_level",
        diameter: 24,
        label: "level",
        min_val: min_val,
        default_val: default_val,
        max_val: max_val,
        visible: false
      )
      knob.xy(@base_x + 22, 149)
      knob.label_offset(-10, -10)
      knob
    end

    def set_pan_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name: "knob_#{@name}_pan",
        diameter: 24,
        label: "pan",
        min_val: min_val,
        default_val: default_val,
        max_val: max_val,
        visible: false
      )
      knob.xy(@base_x + 50, 149)
      knob.label_offset(-10, -10)
      knob
    end
  end
end