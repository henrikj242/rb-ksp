module Ksp
  class UiControl < Variable
    attr_reader :name, :callback

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
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
  end
end
