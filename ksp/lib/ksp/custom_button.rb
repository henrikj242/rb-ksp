module Ksp
  class CustomButton < UiSwitch
    attr_accessor :k_groups, :label
    attr_reader :name

    def initialize(identifer, conf)
      @directory = '_gui'
      @identifier = identifer
      @name = "$button_#{@identifier}"
      @conf = conf
      @conf[:options] ||= []
      image_size = ImageSize.path("#{@directory}/#{@conf[:image]}.png")
      @width = image_size.width
      @height = image_size.height / 6

      # k_groups not currently used, so will not be tested and thus not implemented
      # @k_groups = {
      #     osc1: [],
      #     osc2: []
      # }
    end

    # label not currently used, so will not be tested and thus not implemented
    # def label_exists?
    #   File.exists?(label_file)
    # end
    #
    # def label_file
    #   "#{@directory}/label_#{@conf[:name]}.png"
    # end
    #
    # def label=(ui_image)
    #   @label = ui_image
    # end

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

    def callback
      return "" if @conf[:function] == 'none'

      statements = ["on ui_control(#{name})"]
      if @conf[:function] == 'bypass'
        # k_groups.keys.each do |osc|
        #   k_groups[osc].each do |k_group|
        #     if @conf[:modulator]
        #       stmt << "  $mod_idx_#{@identifier} := find_mod(#{k_group}, \"#{@conf[:modulator]}\") \n"
        #     else
        #       stmt << "  $mod_idx_#{@identifier} := -1 \n"
        #     end
        #     stmt << "  set_engine_par(#{@conf[:parameter]}, #{name}, #{k_group}, $mod_idx_#{@identifier}, -1) \n"
        #   end
        # end
      elsif @conf[:function]
        statements << "call #{@conf[:function]}"
      end
      statements << "end on"
      statements
    end
  end
end