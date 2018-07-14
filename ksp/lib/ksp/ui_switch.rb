module Ksp
  class UiSwitch < UiControl
    def initialize(name:, persistent: true, default_value: nil, visible: true)
      super(type: 'ui_switch', name: name, persistent: persistent,
            default_value: default_value, visible: visible)
    end
  end
end