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
    end

    def set_picture
      "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"#{@picture}\")"
    end

    def set_position
      "move_control_px(#{name}, #{@x}, #{@y})"
    end

    def hide
      "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
    end

    def label=(ui_image)
      @label = ui_image
    end

    def set_callback(callback)
      @callback = callback
    end

    def xy(x, y)
      @x, @y = x, y
    end

    def statements
      super + [
          set_picture,
          set_position,
          hide
      ]
    end
  end
end
