module Ksp
  class CustomFader < UiSlider

    def initialize(identifer, conf)
      super
      @name = "$fader_#{@identifier}"
    end

    def declare
      statements = super
      statements << "set_control_par_str(get_ui_id(#{name}), $CONTROL_PAR_PICTURE, \"fader_#{@conf[:orientation]}\")"
    end
  end
end
