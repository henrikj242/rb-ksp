module Ksp
  class UiControl < Variable
    attr_reader :name
    attr_accessor :callbacks

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
    end

    @callback_statements = []

    # make_persistent
    # set_position_px
    # show / hide
    # set_image stuff



  end
end
