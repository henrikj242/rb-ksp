module Ksp
  class UiSwitch < UiControl
    def initialize(name:, persistent: true, default_value: nil)
      super(type: 'ui_switch', name: name, persistent: persistent, default_value: default_value)
    end
  end
end