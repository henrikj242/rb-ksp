module Ksp
  class UiControl < Variable
    attr_accessor :callback

    def initialize(
          type:,
          name:,
          persistent:     true,
          args:           nil,
          default_value:  nil,
          visible:        true,
          text:           '',
          picture:        nil
    )
      super(
        type:           type,
        name:           name,
        persistent:     persistent,
        args:           args,
        default_value:  default_value
      )
      @gui_directory = '_gui'
      @visible = visible
      @text = text
      @picture = picture
      @callback = UiControlCallback.new(@name)
      set_dimensions
    end

    def text
      "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"#{@text}\")"
    end

    def picture
      if @picture.nil?
        ""
      else
        "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"#{@picture}\")"
      end
    end

    def position
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
      unless @picture.nil?
        image_size = ImageSize.path("#{@gui_directory}/#{@picture}.png")
        @width = width || image_size.width + add_to_width.to_i
        @height = height || image_size.height  + add_to_height.to_i
      end
    end

    def width
      "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_WIDTH, #{@width})"
    end

    def height
      "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_HEIGHT, #{@height})"
    end

    def xy(x, y)
      @x, @y = x, y
    end

    def label
      if @label
        @label.statements
      end
    end

    def statements
      super + label + [
        picture,
        width,
        height,
        position,
        text
      ] + (@visible ? [] : [hide])
    end
  end
end
