module Ksp
  class UiControl < Variable
    attr_accessor :picture
    attr_reader :name, :callback

    def initialize(type:, name:, persistent: true,
                   args: nil, default_value: nil)
      super(
          type: type, name: name, persistent: persistent,
          args: args, default_value: default_value
      )
      @gui_directory = '_gui'
    end

    def set_picture
      "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"#{@picture}\")"
    end

    def set_position
      "move_control_px(#{name}, #{@x}, #{@y})"
    end

    def hide
      "hide_part(#{name}, $HIDE_WHOLE_CONTROL)"
    end

    def show
      "hide_part(#{name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
    end

    def show_all
      "hide_part(#{name}, $HIDE_PART_NOTHING)"
    end

    def set_dimensions(width: nil, height: nil, add_to_width: nil, add_to_height: nil)
      image_size = ImageSize.path("#{@gui_directory}/#{@picture}.png")
      @width = width || image_size.width + add_to_width.to_i
      @height = height || image_size.height  + add_to_height.to_i
      [
          "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,#{@width})",
          "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT,#{@height})"
      ]
    end

    # def label=(ui_image)
    #   @label = ui_image
    # end

    def set_callback(callback)
      @callback = callback
    end

    def xy(x, y)
      @x, @y = x, y
    end

    def statements
      super +
          [set_picture] +
          set_dimensions +
          [set_position]
    end
  end
end
