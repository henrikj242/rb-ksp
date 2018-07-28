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
      title_img.xy(@base_x, 0)
      title_img
    end

    def set_pitch_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name:         "knob_#{@name}_pitch",
        diameter:     44,
        label:        "pitch",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      knob.xy(@base_x + 19, 46)
      knob.label_offset(-18, -42)
      knob
    end

    def set_pitch_mode_button
      button = Beaotic::Button.new(
        name:           "#{@name}_relative",
        persistent:     true,
        default_value:  0,
        visible:        false,
        picture:        "button_pitch_mode"
      )
      button.xy(@base_x, 99)
      button
    end

    def set_level_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name:         "knob_#{@name}_level",
        diameter:     24,
        label:        "mix_level",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      knob.xy(@base_x + 8, 155)
      knob.label_offset(-2, -23)
      knob
    end

    def set_pan_knob(min_val, default_val, max_val)
      knob = Knob.new(
        name:         "knob_#{@name}_pan",
        diameter:     24,
        label:        "mix_pan",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      knob.xy(@base_x + 48, 155)
      knob.label_offset(-2, -23)
      knob
    end

    def set_diode
      diode = Beaotic::Diode.new(name: "diode_#{@name}", levels: 3)
      diode.xy(@base_x + 34, 207)
      diode
    end

    def set_output_menu
      menu = Ksp::UiMenu.new(name: "output_menu_#{@name}", default_value_name: "Default", default_value: -1)
      menu.xy(@base_x + 2, 186)
      menu
    end
  end
end