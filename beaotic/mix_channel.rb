module Beaotic
  class MixChannel
    attr_reader :elements

    def initialize(conf, base_x)
      @conf = conf
      @name = conf[:name]
      @base_x = base_x
      set_elements
    end

    def set_elements
      set_title_image
      @elements = [
          @title_image
      ]
    end

    def set_title_image
      @title_image = Ksp::UiImage.new(
        name:     "title_mix_#{@name}",
        picture:  "title_mix_#{@name}"
      )
      @title_image.xy(@base_x + 5, 0)
    end

    def statements
      # statements = @title_image.declare
      # statements <<
      # statements
      # @elements.map(&:statements)
      # @title_image.statements
    end
  end
end