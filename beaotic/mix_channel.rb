module Beaotic
  class MixChannel
    attr_accessor :elements, :pitch_knob, :pitch_mode_button, :level_knob, :pan_knob, :output_menu, :name

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
      @pitch_knob = Knob.new(
        name:         "#{@name}_pitch",
        diameter:     44,
        label:        "pitch",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      @pitch_knob.xy(@base_x + 19, 46)
      @pitch_knob.label_offset(-18, -42)
      @pitch_knob
    end

    def set_pitch_mode_button
      @pitch_mode_button = Beaotic::Button.new(
        name:           "#{@name}_relative",
        persistent:     true,
        default_value:  0,
        visible:        false,
        picture:        "button_pitch_mode"
      )
      @pitch_mode_button.xy(@base_x, 99)
      @pitch_mode_button
    end

    def set_level_knob(min_val, default_val, max_val)
      @level_knob = Knob.new(
        name:         "#{@name}_level",
        diameter:     24,
        label:        "mix_level",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      @level_knob.xy(@base_x + 8, 155)
      @level_knob.label_offset(-2, -23)
      @level_knob
    end

    def set_pan_knob(min_val, default_val, max_val)
      @pan_knob = Knob.new(
        name:         "#{@name}_pan",
        diameter:     24,
        label:        "mix_pan",
        min_val:      min_val,
        default_val:  default_val,
        max_val:      max_val,
        visible:      false
      )
      @pan_knob.xy(@base_x + 48, 155)
      @pan_knob.label_offset(-2, -23)
      @pan_knob
    end

    def set_diode
      @diode = Diode.new(name: "#{@name}", levels: 3)
      @diode.xy(@base_x + 34, 207)
      @diode
    end

    def set_output_menu
      @output_menu = Ksp::UiMenu.new(name: "output_menu_#{@name}", default_value_name: "Default", default_value: -1)
      @output_menu.xy(@base_x + 2, 186)
      @output_menu
    end
  end
end