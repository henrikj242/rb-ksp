module Ksp
  class UiImage < UiControl
    attr_reader :name
    attr :image_size

    def initialize(identifier, conf = {})
      @gui_directory = '_gui'
      @identifier = identifier
      @name = "$image_#{@identifier}"
      @conf = conf
      # image_size = ImageSize.path("#{@directory}/#{@identifier}.png")
      image_size = ImageSize.path("#{@gui_directory}/#{@conf[:image]}.png")
      @width = image_size.width + ( @conf[:add_to_width] || 0 )
      @height = image_size.height  + ( @conf[:add_to_height] || 0 )
    end

    def declare
      statements = []
      statements << "declare ui_switch #{name}"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE,\"#{@conf[:image]}\")"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,#{@width})"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT,#{@height})"
      # statements << "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
      statements
    end

  end
end