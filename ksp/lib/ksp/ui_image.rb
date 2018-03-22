module Ksp
  class UiImage < UiControl
    attr_reader :name
    attr :image_size

    def initialize(identifer)
      @identifier = identifer
      @name = "$image_#{@identifier}"
      @image_size = { width: 468, height: 16 }
    end

    def image_size=(width: 10, height: 10)
      @image_size = { width: width, height: height }
    end

    def declare
      statements = []
      statements << "declare ui_switch #{name}"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")"
      statements << "set_control_par_str(get_ui_id(#{name}),     $CONTROL_PAR_PICTURE,\"#{@identifier}\")"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,#{image_size[:width]})"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT,#{image_size[:height]})"
    end

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
    end

  end
end