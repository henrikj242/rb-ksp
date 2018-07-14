module Ksp
  class UiImage < UiSwitch
    attr_reader :name
    attr :image_size

    def initialize(image: nil, name:)
      super(name: name, persistent: false)
      @gui_directory = '_gui'
      @image = image || "image_#{name}"
    end

    def set_dimensions(width: nil, height: nil, add_to_width: nil, add_to_height: nil)
      image_size = ImageSize.path("#{@gui_directory}/#{@image}.png")
      @width = width || image_size.width + add_to_width.to_i
      @height = height || image_size.height  + add_to_height.to_i
    end

    def initialize_obsolete(identifier, conf = {})
      @gui_directory = '_gui'
      @identifier = identifier
      @name = "$image_#{@identifier}"
      conf[:image] ||= identifier
      @conf = conf
      # image_size = ImageSize.path("#{@directory}/#{@identifier}.png")
      image_size = ImageSize.path("#{@gui_directory}/#{@conf[:image]}.png")
      @width = image_size.width + ( @conf[:add_to_width] || 0 )
      @height = image_size.height  + ( @conf[:add_to_height] || 0 )
    end

    def declare
      statements = []
      # statements << "declare ui_switch #{name}"
      # statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")"
      # statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE,\"#{@conf[:image]}\")"
      # statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,#{@width})"
      # statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT,#{@height})"
    end

  end
end