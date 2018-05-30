module Ksp
  class UiControl < Variable
    attr_reader :name
    attr_accessor :callbacks

    def set_position(x, y)
      "move_control_px(#{name}, #{x}, #{y})"
    end

    def hide
      "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
    end

    def label=(ui_image)
      @label = ui_image
    end

    @callback_statements = []

    # make_persistent
    # set_position_px
    # show / hide
    # set_image stuff

    def callback
      # return [] if @conf[:function] == 'none'

      statements = ["on ui_control(#{name})"]
      message = "callback: #{name}"
      if @conf[:function] == 'inline'
        k_groups.keys.each do |osc|
          k_groups[osc].each do |k_group|
            if @conf[:modulator]
              message += " modulator: #{@conf[:modulator]}"
              statements << "  $mod_idx_#{@identifier} := find_mod(#{k_group}, \"#{@conf[:modulator]}\")"
            else
              statements << "  $mod_idx_#{@identifier} := -1"
            end
            message += " param: #{@conf[:parameter]}"
            statements << "  set_engine_par(#{@conf[:parameter]}, #{name}, #{k_group}, $mod_idx_#{@identifier}, -1)"
          end
        end
      elsif @conf[:function]
        if @conf[:function] == 'none'
          statements << '{ no finctionality applied }'
        else
          statements << "  call #{@conf[:function].gsub(/^KEY_GROUP/, @conf[:key_group_name])}"
        end
      else
        statements << "  call #{@identifier}"
      end
      statements << "message (\"#{message} val: \" & #{name})"
      statements << 'end on'
      statements
    end
  end
end
