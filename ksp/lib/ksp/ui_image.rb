module Ksp
  class UiImage < UiControl
    attr_reader :name
    attr :image_size

    def initialize(identifier)
      @directory = '_gui'
      @identifier = identifier
      @name = "$image_#{@identifier}"
      image_size = ImageSize.path("#{@directory}/#{@identifier}.png")
      @width = image_size.width
      @height = image_size.height
    end

    # def image_size=(width: 10, height: 10)
    #   @image_size = { width: width, height: height }
    # end
    #
    # def image_size
    #
    # end

    def declare
      statements = []
      statements << "declare ui_switch #{name}"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE,\"#{@identifier}\")"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,#{@width})"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT,#{@height})"
    end

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
    end

  end
end