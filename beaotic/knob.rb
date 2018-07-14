module Beaotic
  class Knob < Ksp::UiSliderV2
    attr_reader :name, :label

    def initialize(name:, diameter: 48, label:, min_val:, default_val:, max_val:)
      super(name: name, args: [min_val, max_val], default_value: default_val)
      @picture = "knob_#{diameter}"
      @label = Ksp::UiImage.new(name: "label_#{name}", picture: "label_#{label}")
    end

    def label_offset(x = 0, y = -16)
      @label.xy(@x + x, @y + y)
    end

    def statements
      super +
          @label.statements + [
          "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")",
          "set_control_par_str(get_ui_id(#{@label.name}), $CONTROL_PAR_TEXT,\"\")",
          "hide_part(#{name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)",
          "hide_part(#{@label.name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      ]
    end
  end
end