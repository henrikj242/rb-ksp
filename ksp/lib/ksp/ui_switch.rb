module Ksp
  class UiSwitch < UiControl
    def initialize(
          name:,
          persistent:     true,
          default_value:  nil,
          visible:        true,
          picture:        nil,
          automatable_as: nil,
          help_text:      nil,
          cc:             nil
    )
      super(
        type:             'ui_switch',
        name:             name,
        persistent:       persistent,
        default_value:    default_value,
        visible:          visible,
        picture:          picture,
        automatable_as:   automatable_as,
        help_text:        help_text,
        cc:               cc
      )
    end
  end
end