module Ksp
  class CustomButton < UiSwitch
    attr_accessor :k_groups, :label
    attr_reader :name, :identifier

    def initialize(identifer, conf)
      @directory = '_gui'
      @identifier = identifer
      @name = "$button_#{@identifier}"
      @conf = conf
      @conf[:options] ||= []
      image_size = ImageSize.path("#{@directory}/#{@conf[:image]}.png")
      @width = image_size.width
      @height = image_size.height / 6

    end

    def declare
      statements = []
      statements << "{ #{name} }"
      statements << "declare ui_switch #{name}"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_TEXT,\"\")"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_AUTOMATION_NAME, \"#{@identifier}\")" unless @conf[:options].include? :no_auto
      # set_control_par(get_ui_id($knob_pitch),$CONTROL_PAR_AUTOMATION_ID,$host_auto_id)
      # inc($host_auto_id)
      statements << "make_persistent(#{name})" unless @conf[:options].include? :no_persist
      statements << "hide_part(#{name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"#{@conf[:image]}\")"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_WIDTH,  #{@width})"
      statements << "set_control_par(get_ui_id(#{name}),     $CONTROL_PAR_HEIGHT, #{@height})"
      statements
    end

  end
end