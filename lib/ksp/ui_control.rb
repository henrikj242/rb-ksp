module Ksp
  class UiControl < Variable
    attr_accessor :label, :x, :y

    def initialize(
          type:,
          name:,
          persistent:         true,
          args:               nil, # [:min_val, :max_val]
          default_value:      nil,
          visible:            true,
          text:               '',
          picture:            nil,
          automatable_as:     nil,
          help_text:          nil,
          cc:                 nil
    )
      super(
        type:           type,
        name:           name,
        persistent:     persistent,
        args:           args,
        default_value:  default_value
      )
      # @gui_directory = KspConfig::conf[:global][:image_base_dir] + '/gui_elements'
      # @gui_directory = Image_base_dir + '/gui_elements'
      @visible = visible
      @text = text
      @picture = picture
      @callbacks = []
      @automatable_as = automatable_as
      @help_text = help_text
      set_dimensions
      add_cc_listener cc
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
        img_file = "#{@gui_directory}/#{@picture}.png"
        txt_file = "#{@gui_directory}/#{@picture}.txt"
        animations = File.open(txt_file, 'r').grep(/Number of Animations/)[0].split(':').last.strip.to_i rescue 1
        image_size = ImageSize.path(img_file)
        @width = width || image_size.width + add_to_width.to_i
        @height = height || (image_size.height / animations) + add_to_height.to_i
      end
    end

    def set_width(width)
      @width = width
    end

    def set_height(height)
      @height = height
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

    def add_callbacks(callback_statements = [])
      @callbacks += Array.wrap(callback_statements)
      # if callback_statements.is_a? String
      #   @callbacks << callback_statements
      # elsif callback_statements.is_a? Array
      #   @callbacks += callback_statements
      # end
    end

    def callbacks
      if @callbacks.count > 0
        ["on ui_control(#{name})"] + @callbacks + ["end on"]
      else
        []
      end
    end

    def add_cc_listener(cc)
      if cc
        cc[:out] = name
        if @args && @args.count == 2
          cc[:min_val] = @args.first
          cc[:max_val] = @args.last
        end
        # KspConfig.add_cc_listener_conf(cc)
      end
    end

    def label_statements
      @label&.on_init.to_a
    end

    def help_text
      if !!@help_text
        "set_control_help(#{name}, \"#{@help_text}\")"
      else
        ""
      end
    end

    # def automatable
    #   [].tap do |statements|
    #     if !!@automatable_as && KspConfig::conf[:with_automation]
    #       statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_NAME, \"#{@automatable_as}\")"
    #       statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_ID, #{AutomationIdCounter.next})"
    #     end
    #   end
    # end

    def statements
      super +
        label_statements +
        [
          picture,
          width,
          height,
          position,
          text,
          help_text
        ] +
        # automatable +
        (@visible ? [] : [hide])
    end
    alias_method :on_init, :statements
  end
end
