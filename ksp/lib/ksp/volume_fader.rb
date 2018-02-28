module Ksp
  class VolumeFader < CustomFader

    def initialize(key_group_name, conf)
      @identifier = "#{key_group_name}_#{conf[:name]}"
      @name = "$volfdr_#{@identifier}"
      @conf = conf
      # @k_groups = {
      #   osc1: [],
      #   osc2: []
      # }
    end

    def callback
      "on ui_control(#{name})" \
        "call #{identifier}_level" \
      'end on'
    end

  end
end