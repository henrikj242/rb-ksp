module Ksp
  class UiImage < UiSwitch
    attr_reader :name
    attr :image_size

    def initialize(
      name:,
      picture:,
      visible:  true
    )
      super(
        name:       name,
        persistent: false,
        picture:    picture,
        visible:    visible
      )
    end
  end
end