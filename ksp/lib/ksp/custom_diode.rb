module Ksp
  class CustomDiode < UiControl

    def initialize(identifer, conf)
      @directory = '_gui'
      @identifier = identifer
      @name = "$diode_#{@identifier}"
      @conf = conf
    end

    def declare
      statements = []
      statements << "{ #{name} }"
      statements << "declare ui_slider #{name}(0, #{@conf[:levels]-1})"
      statements << "hide_part(#{name},$HIDE_WHOLE_CONTROL)"
      statements << "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_VALUE, 0)"
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"diode\")"
      # statements << "#{name} := 0"
    end

  end
end